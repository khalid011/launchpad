import { API_BASE_URL } from './config'

export interface Topic {
  id: number
  name: string
  slug: string
}

export interface ProductScreenshot {
  id: number
  url: string
  displayOrder: number
}

export interface ProductSummary {
  id: number
  name: string
  tagline: string
  logoUrl: string | null
  launchDate: string
  topics: Topic[]
}

export interface ProductDetail extends ProductSummary {
  description: string
  websiteUrl: string
  screenshots: ProductScreenshot[]
}

export async function fetchProducts(): Promise<ProductSummary[]> {
  const res = await fetch(`${API_BASE_URL}/api/products`)
  if (!res.ok) {
    throw new Error(`Failed to fetch products: ${res.status}`)
  }
  return res.json()
}

export async function fetchProduct(id: number): Promise<ProductDetail> {
  const res = await fetch(`${API_BASE_URL}/api/products/${id}`)
  if (!res.ok) {
    throw new Error(`Failed to fetch product ${id}: ${res.status}`)
  }
  return res.json()
}
