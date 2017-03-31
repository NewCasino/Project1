using System;
using System.IdentityModel.Tokens;
using System.ServiceModel.Security.Tokens;
using System.Threading;
using System.Web;
using System.Web.Mvc;

namespace GamMatrix.CMS
{
    public class JsonWebTokenValidationAttribute : AuthorizeAttribute
    {
        public string SymmetricKey { get; set; }
        public string Audience { get; set; }
        public string Issuer { get; set; }
        public bool FailIfNoAuthorizationHeader { get; set; }

        protected override bool AuthorizeCore(HttpContextBase httpContext)
        {
            var header = httpContext.Request.Headers["Authorization"];
            if (string.IsNullOrEmpty(header))
            {
                // return 401 only if FailIfNoAuthorizationHeader is true
                httpContext.Response.SuppressFormsAuthenticationRedirect = FailIfNoAuthorizationHeader;
                return !FailIfNoAuthorizationHeader;
            }

            // always return 401 if there is an Authorization header which is invalid
            httpContext.Response.SuppressFormsAuthenticationRedirect = true;

            string token = header.StartsWith("Bearer ") ? header.Substring(7) : header;

            try
            {
                var tokenHandler = new JwtSecurityTokenHandler();
                var secret = this.SymmetricKey.Replace('-', '+').Replace('_', '/');
                TokenValidationParameters validationParameters = new TokenValidationParameters()
                {
                    AllowedAudience = this.Audience,
                    ValidateIssuer = this.Issuer != null ? true : false,
                    ValidIssuer = this.Issuer,
                    SigningToken = new BinarySecretSecurityToken(Convert.FromBase64String(secret))
                };

                Thread.CurrentPrincipal = HttpContext.Current.User =
                    tokenHandler.ValidateToken(token, validationParameters);

                return true;
            }
            catch (SecurityTokenValidationException)
            {
                return false;
            }
            catch (Exception)
            {
                return false;
            }
        }
    }
}