import fs from "fs";
import matter, { GrayMatterFile } from "gray-matter";
import path from "path";
import { unified } from "unified";
import remarkParse from "remark-parse";
import rehypeSlug from "rehype-slug";
import rehypeStringify from "rehype-stringify";
import remarkRehype from "remark-rehype";
import jsdom from "jsdom";

const baseDir = "./_content/";

const contentMap: Record<string, GrayMatterFile<string>> = {};

const readContent = (fp: string): GrayMatterFile<string> => {
  if (!contentMap[fp]) {
    const file = fs.readFileSync(fp, "utf8");
    const m = matter(file);
    const date = m.data.date;
    if (date) {
      m.data.date = "";
      const d = date.split("-");
      const from = d[0]?.trim();
      const to = d[1]?.trim();
      if (from) {
        m.data.date += new Date(from).toDateString();
      }
      if (to) {
        m.data.date += ` - ${new Date(to).toDateString()}`;
      }
    }
    m.data.slug = path.parse(fp).name;
    contentMap[fp] = m;
    return m;
  }
  return contentMap[fp];
};

const getAllPathsRecursive = (base = baseDir): string[] => {
  let results = [] as string[];
  const files = fs.readdirSync(base);
  for (const file of files) {
    const filePath = path.resolve(base, file);
    const stat = fs.statSync(filePath);
    if (stat.isDirectory()) {
      results = results.concat(getAllPathsRecursive(filePath));
    } else if (path.extname(filePath) === ".md") {
      results.push(filePath);
    }
  }
  return results;
};

export const getAllPaths = (): string[] => getAllPathsRecursive(baseDir);

export const getCases = (): GrayMatterFile<string>[] =>
  getAllPaths()
    .filter(p => p.includes("/cases/"))
    .map(readContent);

export const getAllContent = (): GrayMatterFile<string>[] =>
  getAllPaths()
    .map(readContent);

export const getContent = (slug: string): GrayMatterFile<string> =>
  getAllContent()
    .find(c => c.data.slug === slug) || {} as any

export const getHeaders = (content: string): { id: string; text: string }[] => {
  const prc = unified().use(remarkParse).use(remarkRehype).use(rehypeSlug).use(rehypeStringify);
  const html = prc.processSync(content).value.toString();
  const dom = new jsdom.JSDOM(html);
  const h1 = dom.window.document.querySelectorAll("h1");
  const h2 = dom.window.document.querySelectorAll("h2");
  const h3 = dom.window.document.querySelectorAll("h3");
  const h4 = dom.window.document.querySelectorAll("h4");
  const h5 = dom.window.document.querySelectorAll("h5");
  const h6 = dom.window.document.querySelectorAll("h6");
  const res = [] as { id: string; text: string }[];
  h1.forEach(v => res.push({ id: v.id, text: v.textContent ?? "" }));
  h2.forEach(v => res.push({ id: v.id, text: v.textContent ?? "" }));
  h3.forEach(v => res.push({ id: v.id, text: v.textContent ?? "" }));
  h4.forEach(v => res.push({ id: v.id, text: v.textContent ?? "" }));
  h5.forEach(v => res.push({ id: v.id, text: v.textContent ?? "" }));
  h6.forEach(v => res.push({ id: v.id, text: v.textContent ?? "" }));
  return res;
};
