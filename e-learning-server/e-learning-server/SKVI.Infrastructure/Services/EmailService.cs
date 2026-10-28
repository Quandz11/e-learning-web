using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Options;
using MimeKit;
using SKVI.Application.Interfaces;

namespace SKVI.Infrastructure.Security;

public class EmailService : IEmailService
{
    private readonly SmtpSettings _smtpSettings;

    public EmailService(IOptions<SmtpSettings> smtpSettings)
    {
        _smtpSettings = smtpSettings.Value;
    }

    public async Task SendEmailAsync(
        string to,
        string subject,
        string body)
    {
        var email = new MimeMessage();

        email.From.Add(new MailboxAddress(
            _smtpSettings.SenderName,
            _smtpSettings.SenderEmail
        ));

        email.To.Add(MailboxAddress.Parse(to));
        email.Subject = subject;

        email.Body = new BodyBuilder
        {
            HtmlBody = body
        }.ToMessageBody();

        using var smtp = new SmtpClient();

        try
        {
            await smtp.ConnectAsync(
                _smtpSettings.Server,
                _smtpSettings.Port,
                SecureSocketOptions.Auto
            );

            await smtp.AuthenticateAsync(
                _smtpSettings.Username,
                _smtpSettings.Password
            );

            await smtp.SendAsync(email);
        }
        finally
        {
            if (smtp.IsConnected)
            {
                await smtp.DisconnectAsync(true);
            }
        }
    }
}
