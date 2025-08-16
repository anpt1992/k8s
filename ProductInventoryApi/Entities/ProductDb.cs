using Microsoft.EntityFrameworkCore;

namespace ProductInventoryApi.Entities
{
    public class ProductDb : DbContext
    {
        public ProductDb(DbContextOptions<ProductDb> options) : base(options) { }
        public DbSet<Product> Products => Set<Product>();
    }
}
