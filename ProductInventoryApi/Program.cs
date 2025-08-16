using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;


var builder = WebApplication.CreateBuilder(args);
builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenAnyIP(9090);
});
builder.Services.AddDbContext<ProductDb>(opt => opt.UseInMemoryDatabase("ProductInventory"));
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();

app.MapGet("/products", async (ProductDb db) => await db.Products.ToListAsync());
app.MapGet("/products/{id}", async (int id, ProductDb db) => await db.Products.FindAsync(id) is Product p ? Results.Ok(p) : Results.NotFound());
app.MapPost("/products", async (Product product, ProductDb db) => { db.Products.Add(product); await db.SaveChangesAsync(); return Results.Created($"/products/{product.Id}", product); });
app.MapPut("/products/{id}", async (int id, Product inputProduct, ProductDb db) => {
    var product = await db.Products.FindAsync(id);
    if (product is null) return Results.NotFound();
    product.Name = inputProduct.Name;
    product.Price = inputProduct.Price;
    product.Quantity = inputProduct.Quantity;
    await db.SaveChangesAsync();
    return Results.NoContent();
});
app.MapDelete("/products/{id}", async (int id, ProductDb db) => {
    var product = await db.Products.FindAsync(id);
    if (product is null) return Results.NotFound();
    db.Products.Remove(product);
    await db.SaveChangesAsync();
    return Results.NoContent();
});

app.Run();

class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public int Quantity { get; set; }
}

class ProductDb : DbContext
{
    public ProductDb(DbContextOptions<ProductDb> options) : base(options) { }
    public DbSet<Product> Products => Set<Product>();
}
