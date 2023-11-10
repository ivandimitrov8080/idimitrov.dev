import GithubSvg from "@/components/svg/github-svg";
import GitlabSvg from "@/components/svg/gitlab-svg";
import Link from "next/link";

export default function Links() {

  const links = [
    <Link aria-label="GitHub" href={process.env.NEXT_PUBLIC_GITHUB_URL!} target="_blank">
      <GithubSvg />
    </Link>
    ,
    <Link aria-label="GitLab" href={process.env.NEXT_PUBLIC_GITLAB_URL!} target="_blank">
      <GitlabSvg />
    </Link>
  ]

  return (
    <main className="place-content-center text-center">
      <div className={`grid grid-cols-${links.length} gap-4`}>
        {links}
      </div>
    </main>
  )
}
