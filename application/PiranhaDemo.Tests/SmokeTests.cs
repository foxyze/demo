using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;

namespace PiranhaDemo.Tests;

public class SmokeTests : IClassFixture<PiranhaFactory>
{
    private readonly HttpClient _client;

    public SmokeTests(PiranhaFactory factory)
    {
        _client = factory.CreateClient(new WebApplicationFactoryClientOptions { AllowAutoRedirect = false });
    }

    [Fact]
    public async Task Home_ReturnsOk()
    {
        var response = await _client.GetAsync("/");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Manager_RedirectsToLogin()
    {
        var response = await _client.GetAsync("/manager");

        Assert.Equal(HttpStatusCode.Redirect, response.StatusCode);
        Assert.StartsWith("/manager/login", response.Headers.Location?.PathAndQuery);
    }

    [Fact]
    public async Task ManagerLogin_ReturnsOk()
    {
        var response = await _client.GetAsync("/manager/login");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
