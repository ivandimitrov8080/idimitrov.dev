import Link from "next/link";

export default function Cases() {
  const cases: any = [] as any
  return (
    <ul className="menu min-h-[95vh] h-max space-y-4 m-auto">
      {cases.map((project: any) => (
        <li className="m-auto" key={project.id}>
          <Link className="rounded-3xl" href={`project/${project.id}`}>
            <div>
              hehe
            </div>
          </Link>
        </li>
      ))}
    </ul>
  )
}
