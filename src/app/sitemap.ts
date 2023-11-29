import { getAllContent } from "$lib/content"
import { MetadataRoute } from "next"

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    {
      url: "https://idimitrov.dev/",
      lastModified: new Date(),
      changeFrequency: "weekly",
      priority: 1,
    },
    {
      url: "https://idimitrov.dev/cases",
      lastModified: new Date(),
      changeFrequency: "weekly",
      priority: 0.8,
    },
    {
      url: "https://idimitrov.dev/contact",
      lastModified: new Date(),
      changeFrequency: "weekly",
      priority: 0.5,
    },
    ...getAllContent().map(c => c.data).map(d => {
      return {
        url: `https://idimitrov.dev${d.slug}`,
        lastModified: new Date(),
        changeFrequency: "weekly",
        priority: d.priority || 0.8
      } as any
    })
  ]
}
