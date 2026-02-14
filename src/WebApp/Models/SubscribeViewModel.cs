using System.ComponentModel.DataAnnotations;

namespace WebApp.Models;

public class SubscribeViewModel
{
    [Required(ErrorMessage = "Email address is required.")]
    [EmailAddress(ErrorMessage = "Please enter a valid email address (e.g. name@example.com).")]
    [Display(Name = "Email Address")]
    public string Email { get; set; } = string.Empty;
}
