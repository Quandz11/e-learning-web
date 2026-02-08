using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Forum;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class ForumService
{
    private readonly ApplicationDbContext _context;

    public ForumService(ApplicationDbContext context)
    {
        _context = context;
    }

    #region Categories

    public async Task<List<ForumCategoryDto>> GetAllCategoriesAsync()
    {
        return await _context.ForumCategories
            .Where(c => c.IsActive)
            .OrderBy(c => c.Order)
            .Select(c => new ForumCategoryDto
            {
                Id = c.Id,
                Name = c.Name,
                Description = c.Description,
                Icon = c.Icon,
                Order = c.Order,
                IsActive = c.IsActive,
                ThreadCount = c.Threads.Count,
                CreatedAt = c.CreatedAt
            })
            .ToListAsync();
    }

    public async Task<ForumCategoryDto?> GetCategoryByIdAsync(Guid id)
    {
        return await _context.ForumCategories
            .Where(c => c.Id == id)
            .Select(c => new ForumCategoryDto
            {
                Id = c.Id,
                Name = c.Name,
                Description = c.Description,
                Icon = c.Icon,
                Order = c.Order,
                IsActive = c.IsActive,
                ThreadCount = c.Threads.Count,
                CreatedAt = c.CreatedAt
            })
            .FirstOrDefaultAsync();
    }

    public async Task<ForumCategoryDto> CreateCategoryAsync(CreateForumCategoryRequest request)
    {
        var category = new ForumCategory
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            Description = request.Description,
            Icon = request.Icon,
            Order = request.Order,
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow
        };

        _context.ForumCategories.Add(category);
        await _context.SaveChangesAsync();

        return (await GetCategoryByIdAsync(category.Id))!;
    }

    public async Task<ForumCategoryDto> UpdateCategoryAsync(Guid id, UpdateForumCategoryRequest request)
    {
        var category = await _context.ForumCategories.FindAsync(id);
        if (category == null)
        {
            throw new Exception("Category not found");
        }

        category.Name = request.Name;
        category.Description = request.Description;
        category.Icon = request.Icon;
        category.Order = request.Order;
        category.IsActive = request.IsActive;
        category.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return (await GetCategoryByIdAsync(category.Id))!;
    }

    public async Task DeleteCategoryAsync(Guid id)
    {
        var category = await _context.ForumCategories.FindAsync(id);
        if (category == null)
        {
            throw new Exception("Category not found");
        }

        _context.ForumCategories.Remove(category);
        await _context.SaveChangesAsync();
    }

    #endregion

    #region Threads

    public async Task<List<ForumThreadDto>> GetThreadsByCategoryAsync(Guid categoryId)
    {
        return await _context.ForumThreads
            .Include(t => t.Category)
            .Include(t => t.Author)
            .Where(t => t.CategoryId == categoryId)
            .OrderByDescending(t => t.LastPostAt ?? t.CreatedAt)
            .Select(t => new ForumThreadDto
            {
                Id = t.Id,
                CategoryId = t.CategoryId,
                CategoryName = t.Category.Name,
                AuthorId = t.AuthorId,
                AuthorName = t.Author.FullName ?? t.Author.Email,
                AuthorAvatarUrl = t.Author.AvatarUrl,
                Title = t.Title,
                Content = t.Content,
                ViewCount = t.ViewCount,
                PostCount = t.Posts.Count,
                CreatedAt = t.CreatedAt,
                UpdatedAt = t.UpdatedAt,
                LastPostAt = t.LastPostAt
            })
            .ToListAsync();
    }

    public async Task<ForumThreadDto?> GetThreadByIdAsync(Guid id)
    {
        var thread = await _context.ForumThreads
            .Include(t => t.Category)
            .Include(t => t.Author)
            .Where(t => t.Id == id)
            .Select(t => new ForumThreadDto
            {
                Id = t.Id,
                CategoryId = t.CategoryId,
                CategoryName = t.Category.Name,
                AuthorId = t.AuthorId,
                AuthorName = t.Author.FullName ?? t.Author.Email,
                AuthorAvatarUrl = t.Author.AvatarUrl,
                Title = t.Title,
                Content = t.Content,
                ViewCount = t.ViewCount,
                PostCount = t.Posts.Count,
                CreatedAt = t.CreatedAt,
                UpdatedAt = t.UpdatedAt,
                LastPostAt = t.LastPostAt
            })
            .FirstOrDefaultAsync();

        // Increment view count
        if (thread != null)
        {
            var threadEntity = await _context.ForumThreads.FindAsync(id);
            if (threadEntity != null)
            {
                threadEntity.ViewCount++;
                await _context.SaveChangesAsync();
            }
        }

        return thread;
    }

    public async Task<ForumThreadDto> CreateThreadAsync(CreateForumThreadRequest request, Guid authorId)
    {
        var thread = new ForumThread
        {
            Id = Guid.NewGuid(),
            CategoryId = request.CategoryId,
            AuthorId = authorId,
            Title = request.Title,
            Content = request.Content,
            ViewCount = 0,
            CreatedAt = DateTime.UtcNow,
            LastPostAt = DateTime.UtcNow
        };

        _context.ForumThreads.Add(thread);
        await _context.SaveChangesAsync();

        return (await GetThreadByIdAsync(thread.Id))!;
    }

    public async Task<ForumThreadDto> UpdateThreadAsync(Guid id, UpdateForumThreadRequest request, Guid userId)
    {
        var thread = await _context.ForumThreads.FindAsync(id);
        if (thread == null)
        {
            throw new Exception("Thread not found");
        }

        // Only author can update
        if (thread.AuthorId != userId)
        {
            throw new UnauthorizedAccessException("Only the author can update this thread");
        }

        thread.Title = request.Title;
        thread.Content = request.Content;
        thread.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return (await GetThreadByIdAsync(thread.Id))!;
    }

    public async Task DeleteThreadAsync(Guid id, Guid userId, bool isAdmin = false)
    {
        var thread = await _context.ForumThreads.FindAsync(id);
        if (thread == null)
        {
            throw new Exception("Thread not found");
        }

        // Only author or admin can delete
        if (!isAdmin && thread.AuthorId != userId)
        {
            throw new UnauthorizedAccessException("Only the author or admin can delete this thread");
        }

        _context.ForumThreads.Remove(thread);
        await _context.SaveChangesAsync();
    }

    #endregion

    #region Posts

    public async Task<List<ForumPostDto>> GetPostsByThreadAsync(Guid threadId)
    {
        return await _context.ForumPosts
            .Include(p => p.Author)
            .Where(p => p.ThreadId == threadId)
            .OrderBy(p => p.CreatedAt)
            .Select(p => new ForumPostDto
            {
                Id = p.Id,
                ThreadId = p.ThreadId,
                AuthorId = p.AuthorId,
                AuthorName = p.Author.FullName ?? p.Author.Email,
                AuthorAvatarUrl = p.Author.AvatarUrl,
                Content = p.Content,
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt
            })
            .ToListAsync();
    }

    public async Task<ForumPostDto> CreatePostAsync(CreateForumPostRequest request, Guid authorId)
    {
        var post = new ForumPost
        {
            Id = Guid.NewGuid(),
            ThreadId = request.ThreadId,
            AuthorId = authorId,
            Content = request.Content,
            CreatedAt = DateTime.UtcNow
        };

        _context.ForumPosts.Add(post);

        // Update thread's LastPostAt
        var thread = await _context.ForumThreads.FindAsync(request.ThreadId);
        if (thread != null)
        {
            thread.LastPostAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();

        return new ForumPostDto
        {
            Id = post.Id,
            ThreadId = post.ThreadId,
            AuthorId = post.AuthorId,
            AuthorName = "",
            Content = post.Content,
            CreatedAt = post.CreatedAt
        };
    }

    public async Task<ForumPostDto> UpdatePostAsync(Guid id, UpdateForumPostRequest request, Guid userId)
    {
        var post = await _context.ForumPosts.FindAsync(id);
        if (post == null)
        {
            throw new Exception("Post not found");
        }

        // Only author can update
        if (post.AuthorId != userId)
        {
            throw new UnauthorizedAccessException("Only the author can update this post");
        }

        post.Content = request.Content;
        post.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return (await _context.ForumPosts
            .Include(p => p.Author)
            .Where(p => p.Id == id)
            .Select(p => new ForumPostDto
            {
                Id = p.Id,
                ThreadId = p.ThreadId,
                AuthorId = p.AuthorId,
                AuthorName = p.Author.FullName ?? p.Author.Email,
                AuthorAvatarUrl = p.Author.AvatarUrl,
                Content = p.Content,
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt
            })
            .FirstOrDefaultAsync())!;
    }

    public async Task DeletePostAsync(Guid id, Guid userId, bool isAdmin = false)
    {
        var post = await _context.ForumPosts.FindAsync(id);
        if (post == null)
        {
            throw new Exception("Post not found");
        }

        // Only author or admin can delete
        if (!isAdmin && post.AuthorId != userId)
        {
            throw new UnauthorizedAccessException("Only the author or admin can delete this post");
        }

        _context.ForumPosts.Remove(post);
        await _context.SaveChangesAsync();
    }

    #endregion
}
