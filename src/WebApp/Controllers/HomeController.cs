using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using WebApp.Models;

namespace WebApp.Controllers;

public class HomeController : Controller
{
    private static readonly List<SubscriberEntry> _subscribers = new();

    public IActionResult Index()
    {
        return View(new SubscribeViewModel());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Subscribe(SubscribeViewModel model)
    {
        if (!ModelState.IsValid)
        {
            return View("Index", model);
        }

        if (_subscribers.Any(s => s.Email.Equals(model.Email, StringComparison.OrdinalIgnoreCase)))
        {
            TempData["SubscribeError"] = $"{model.Email} is already subscribed.";
            return RedirectToAction("Index");
        }

        _subscribers.Add(new SubscriberEntry
        {
            Email = model.Email,
            SubscribedAt = DateTime.UtcNow
        });

        TempData["SubscribeSuccess"] = $"Thank you! {model.Email} has been subscribed successfully.";
        return RedirectToAction("Index");
    }

    public IActionResult Subscribers()
    {
        return View(_subscribers.OrderByDescending(s => s.SubscribedAt).ToList());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult DeleteSubscriber(string email)
    {
        var subscriber = _subscribers.FirstOrDefault(s => s.Email.Equals(email, StringComparison.OrdinalIgnoreCase));
        if (subscriber != null)
        {
            _subscribers.Remove(subscriber);
            TempData["SubscribersMessage"] = $"{email} has been removed.";
        }

        return RedirectToAction("Subscribers");
    }

    public IActionResult Privacy()
    {
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
