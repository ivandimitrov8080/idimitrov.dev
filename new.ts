import { baseDir, getAllContent } from "@/app/lib/content";
import fs from "fs"

const args = process.argv.slice(2)

const path = args[0]

if (!path) {
  throw new Error("Path is needed!")
}

const slug = path.split("/");
const t = slug[slug.length - 1]

const nextZ = Math.max.apply(Math, getAllContent().map(c => Number(c.data.z))) + 1

const meta = (title: string = t, goal: string = "", role: string = "", date: string = "", z: number = nextZ) => `---
title: ${title}
goal: ${goal}
role: ${role}
date: ${date}
z: ${z}
draft: true
---
`

fs.writeFileSync(`${baseDir}${path}.md`, meta(), {flag: "w+"})

