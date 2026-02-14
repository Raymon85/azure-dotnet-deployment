using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using WebApp.Models;

namespace WebApp.Controllers;

public class HomeController : Controller
{
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

        TempData["SubscribeSuccess"] = $"Thank you! {model.Email} has been subscribed successfully.";
        return RedirectToAction("Index");
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
