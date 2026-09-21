import type { ProductSummary } from '../api/products'

interface ProductCardProps {
  product: ProductSummary
}

function ProductCard({ product }: ProductCardProps) {
  return (
    <div>
      {product.logoUrl ? (
        <img src={product.logoUrl} alt={`${product.name} logo`} width={48} height={48} />
      ) : (
        <div>{product.name.charAt(0).toUpperCase()}</div>
      )}
      <h3>{product.name}</h3>
      <p>{product.tagline}</p>
      <div>{product.topics.map((topic) => topic.name).join(', ')}</div>
    </div>
  )
}

export default ProductCard
