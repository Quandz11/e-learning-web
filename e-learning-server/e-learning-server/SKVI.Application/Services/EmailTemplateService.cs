using System;
using System.Net;

namespace SKVI.Application.Services;

public static class EmailTemplateService
{
    public static string RegistrationOtp(string otp) =>
        Build(
            "Xác thực tài khoản",
            "Cảm ơn bạn đã đăng ký SKVI E-Learning. " +
            "Vui lòng sử dụng mã dưới đây để hoàn tất xác thực tài khoản.",
            otp
        );

    public static string ResendRegistrationOtp(string otp) =>
        Build(
            "Mã xác thực mới",
            "Bạn đã yêu cầu gửi lại mã xác thực tài khoản. " +
            "Vui lòng sử dụng mã mới bên dưới để tiếp tục.",
            otp
        );

    public static string ForgotPasswordOtp(string otp) =>
        Build(
            "Đặt lại mật khẩu",
            "Chúng tôi đã nhận được yêu cầu đặt lại mật khẩu " +
            "cho tài khoản SKVI E-Learning của bạn. " +
            "Vui lòng sử dụng mã bên dưới để tiếp tục.",
            otp
        );

    private static string Build(
        string title,
        string description,
        string otp)
    {
        var safeTitle = WebUtility.HtmlEncode(title);
        var safeDescription = WebUtility.HtmlEncode(description);
        var safeOtp = WebUtility.HtmlEncode(otp);

        return $$"""
        <!DOCTYPE html>
        <html lang="vi">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>{{safeTitle}}</title>
        </head>
        <body style="margin:0;padding:0;background:#F1F1F1;font-family:Arial,Helvetica,sans-serif;color:#263D3B;">
          <table role="presentation" cellpadding="0" cellspacing="0" border="0"
                 width="100%" style="background:#F1F1F1;">
            <tr>
              <td align="center" style="padding:32px 12px;">
                <table role="presentation" cellpadding="0" cellspacing="0" border="0"
                       width="100%" style="max-width:560px;background:#FFFFFF;">

                  <tr>
                    <td align="center" style="background:#C0DDDA;padding:30px 20px;">
                      <div style="font-size:20px;font-weight:bold;letter-spacing:0.4px;color:#244C49;">
                        NHỊN ĂN CHỮA LÀNH
                      </div>
                      <div style="font-size:13px;color:#426966;margin-top:7px;">
                        SKVI E-Learning
                      </div>
                    </td>
                  </tr>

                  <tr>
                    <td style="padding:34px 30px;">
                      <h1 style="font-size:25px;line-height:1.3;margin:0 0 20px;color:#263D3B;">
                        {{safeTitle}}
                      </h1>

                      <p style="font-size:15px;line-height:1.8;color:#536460;margin:0 0 12px;">
                        Xin chào,
                      </p>

                      <p style="font-size:15px;line-height:1.8;color:#536460;margin:0 0 26px;">
                        {{safeDescription}}
                      </p>

                      <table role="presentation" width="100%" cellpadding="0" cellspacing="0"
                             style="background:#F7F9F8;border:1px solid #E3EBE8;">
                        <tr>
                          <td align="center" style="padding:26px 12px;">
                            <div style="font-size:12px;letter-spacing:2px;color:#657E78;font-weight:bold;">
                              MÃ XÁC THỰC
                            </div>

                            <div style="font-size:36px;line-height:1.4;letter-spacing:7px;font-weight:bold;color:#254F49;margin:12px 0;">
                              {{safeOtp}}
                            </div>

                            <div style="display:inline-block;background:#FBE29D;padding:8px 15px;font-size:12px;color:#66521F;">
                              Có hiệu lực trong 10 phút
                            </div>
                          </td>
                        </tr>
                      </table>

                      <p style="font-size:14px;line-height:1.8;color:#536460;margin:26px 0 0;">
                        Để bảo vệ tài khoản, vui lòng không chia sẻ mã này với bất kỳ ai.
                      </p>

                      <p style="font-size:13px;line-height:1.8;color:#788781;margin:16px 0 0;">
                        Nếu bạn không thực hiện yêu cầu này, hãy bỏ qua email.
                      </p>
                    </td>
                  </tr>

                  <tr>
                    <td align="center" style="border-top:1px solid #E3EBE8;padding:24px 20px;">
                      <div style="font-size:12px;color:#788781;line-height:1.8;">
                        Email tự động từ SKVI E-Learning<br>
                        © {{DateTime.UtcNow.Year}} Nhịn Ăn Chữa Lành
                      </div>
                    </td>
                  </tr>

                </table>
              </td>
            </tr>
          </table>
        </body>
        </html>
        """;
    }
}
