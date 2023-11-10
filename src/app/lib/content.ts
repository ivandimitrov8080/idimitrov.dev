import fs from "fs";
import path from "path";

const baseDir = "./_content/"

export const getContent = (slug: string[]): string => {
  let p = path.join(baseDir)
  slug.forEach(s => {
    p = path.join(p, s)
  })
  const file = fs.readFileSync(p, "utf8")
  return file
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

export const getAllPaths = (): string[] => {
  return getAllPathsRecursive().map(p => p.substring(9))
}

