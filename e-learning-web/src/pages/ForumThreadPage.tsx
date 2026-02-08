import React, { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useSelector } from 'react-redux';
import type { RootState } from '../store/store';
import { forumApi, type ForumThreadDto, type ForumPostDto, type CreateForumPostRequest } from '../services/forumApi';
import { ArrowLeft, Clock, Send } from 'lucide-react';
import { toast } from 'react-hot-toast';

const ForumThreadPage: React.FC = () => {
    const { threadId } = useParams<{ threadId: string }>();
    const { t } = useTranslation();
    const { user } = useSelector((state: RootState) => state.auth);
    const [thread, setThread] = useState<ForumThreadDto | null>(null);
    const [posts, setPosts] = useState<ForumPostDto[]>([]);
    const [loading, setLoading] = useState(true);
    const [replyContent, setReplyContent] = useState('');
    const [submitting, setSubmitting] = useState(false);

    useEffect(() => {
        if (threadId) {
            fetchData();
        }
    }, [threadId]);

    const fetchData = async () => {
        if (!threadId) return;

        try {
            const [threadData, postsData] = await Promise.all([
                forumApi.threads.getById(threadId),
                forumApi.posts.getByThread(threadId)
            ]);
            setThread(threadData);
            setPosts(postsData);
        } catch (error) {
            console.error('Failed to fetch thread data:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleSubmitReply = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!threadId || !replyContent.trim() || !user) return;

        try {
            setSubmitting(true);
            const request: CreateForumPostRequest = {
                threadId,
                content: replyContent.trim()
            };
            await forumApi.posts.create(request);
            setReplyContent('');
            toast.success(t('forum.replyPosted', { defaultValue: 'Reply posted successfully' }));
            await fetchData(); // Refresh posts
        } catch (error) {
            console.error('Failed to post reply:', error);
            toast.error(t('forum.replyFailed', { defaultValue: 'Failed to post reply' }));
        } finally {
            setSubmitting(false);
        }
    };

    const formatDate = (dateString: string) => {
        return new Date(dateString).toLocaleDateString('vi-VN', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    };

    if (loading) {
        return (
            <div className="container mx-auto px-4 py-8">
                <div className="animate-pulse space-y-4">
                    <div className="h-32 bg-gray-200 dark:bg-gray-700 rounded-xl" />
                    {[1, 2, 3].map(i => (
                        <div key={i} className="h-24 bg-gray-200 dark:bg-gray-700 rounded-xl" />
                    ))}
                </div>
            </div>
        );
    }

    if (!thread) {
        return (
            <div className="container mx-auto px-4 py-8 text-center">
                <p className="text-gray-600 dark:text-gray-400">
                    {t('forum.threadNotFound', { defaultValue: 'Thread not found' })}
                </p>
            </div>
        );
    }

    return (
        <div className="container mx-auto px-4 py-8 max-w-4xl">
            {/* Back Link */}
            <Link
                to={`/forum/category/${thread.categoryId}`}
                className="inline-flex items-center gap-2 text-primary hover:text-primary/80 mb-6"
            >
                <ArrowLeft className="w-4 h-4" />
                {t('forum.backToCategory', { defaultValue: 'Back to' })} {thread.categoryName}
            </Link>

            {/* Thread Header */}
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6 mb-6">
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
                    {thread.title}
                </h1>

                <div className="flex items-start gap-4">
                    {/* Author Avatar */}
                    {thread.authorAvatarUrl ? (
                        <img
                            src={thread.authorAvatarUrl}
                            alt={thread.authorName}
                            className="w-12 h-12 rounded-full object-cover"
                        />
                    ) : (
                        <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center">
                            <span className="text-primary font-semibold text-lg">
                                {thread.authorName.charAt(0).toUpperCase()}
                            </span>
                        </div>
                    )}

                    {/* Thread Content */}
                    <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                            <span className="font-semibold text-gray-900 dark:text-white">
                                {thread.authorName}
                            </span>
                            <span className="text-sm text-gray-500 dark:text-gray-400 flex items-center gap-1">
                                <Clock className="w-3 h-3" />
                                {formatDate(thread.createdAt)}
                            </span>
                        </div>
                        <div className="text-gray-700 dark:text-gray-300 whitespace-pre-wrap">
                            {thread.content}
                        </div>
                    </div>
                </div>
            </div>

            {/* Posts */}
            <div className="space-y-4 mb-6">
                {posts.map(post => (
                    <div
                        key={post.id}
                        className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6"
                    >
                        <div className="flex items-start gap-4">
                            {/* Author Avatar */}
                            {post.authorAvatarUrl ? (
                                <img
                                    src={post.authorAvatarUrl}
                                    alt={post.authorName}
                                    className="w-10 h-10 rounded-full object-cover"
                                />
                            ) : (
                                <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                                    <span className="text-primary font-semibold">
                                        {post.authorName.charAt(0).toUpperCase()}
                                    </span>
                                </div>
                            )}

                            {/* Post Content */}
                            <div className="flex-1">
                                <div className="flex items-center gap-2 mb-2">
                                    <span className="font-semibold text-gray-900 dark:text-white">
                                        {post.authorName}
                                    </span>
                                    <span className="text-sm text-gray-500 dark:text-gray-400 flex items-center gap-1">
                                        <Clock className="w-3 h-3" />
                                        {formatDate(post.createdAt)}
                                    </span>
                                    {post.updatedAt && post.updatedAt !== post.createdAt && (
                                        <span className="text-xs text-gray-400 dark:text-gray-500">
                                            ({t('forum.edited', { defaultValue: 'edited' })})
                                        </span>
                                    )}
                                </div>
                                <div className="text-gray-700 dark:text-gray-300 whitespace-pre-wrap">
                                    {post.content}
                                </div>
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            {/* Reply Form */}
            {user ? (
                <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6">
                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                        {t('forum.postReply', { defaultValue: 'Post a Reply' })}
                    </h3>
                    <form onSubmit={handleSubmitReply}>
                        <textarea
                            value={replyContent}
                            onChange={e => setReplyContent(e.target.value)}
                            placeholder={t('forum.replyPlaceholder', { defaultValue: 'Write your reply...' })}
                            className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary resize-none"
                            rows={4}
                            required
                        />
                        <div className="mt-4 flex justify-end">
                            <button
                                type="submit"
                                disabled={submitting || !replyContent.trim()}
                                className="flex items-center gap-2 px-6 py-2 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                            >
                                <Send className="w-4 h-4" />
                                {submitting ? t('forum.posting', { defaultValue: 'Posting...' }) : t('forum.postReply', { defaultValue: 'Post Reply' })}
                            </button>
                        </div>
                    </form>
                </div>
            ) : (
                <div className="bg-gray-50 dark:bg-gray-800/50 rounded-xl border border-gray-200 dark:border-gray-700 p-6 text-center">
                    <p className="text-gray-600 dark:text-gray-400 mb-4">
                        {t('forum.loginToReply', { defaultValue: 'Please login to post a reply' })}
                    </p>
                    <Link
                        to="/login"
                        className="inline-block px-6 py-2 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors"
                    >
                        {t('auth.login', { defaultValue: 'Login' })}
                    </Link>
                </div>
            )}
        </div>
    );
};

export default ForumThreadPage;
