import fs from "fs";
import matter, { GrayMatterFile } from "gray-matter";
import path from "path";

const baseDir = "./_content/"

export const getContent = (slug: string[]): GrayMatterFile<string> => {
  let p = path.join(baseDir)
  slug.forEach(s => {
    p = path.join(p, s)
  })
  const file = fs.readFileSync(p, "utf8")
  const m = matter(file);
  m.data.slug = `/c/${slug.join("/")}`
  return m
}

const getAllPathsRecursive = (base = baseDir): string[] => {
  let results = [] as string[];

  const files = fs.readdirSync(base);

  for (const file of files) {
    const filePath = path.join(base, file);
    const stat = fs.statSync(filePath);

    if (stat.isDirectory()) {
      results = results.concat(getAllPathsRecursive(filePath));
    } else if (path.extname(filePath) === '.md') {
      results.push(filePath);
    }
  }
  return results;
}

export const getAllPaths = (base = baseDir): string[] => {
  return getAllPathsRecursive(base).map(p => p.substring(9))
}

export const getCases = (): GrayMatterFile<string>[] => {
  return getAllPaths(`${baseDir}cases/`).map(s => s.split("/")).map(getContent)
}

