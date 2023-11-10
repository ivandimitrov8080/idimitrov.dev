import { faGithub, faGitlab } from "@fortawesome/free-brands-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import Link from "next/link";

export default function Links() {

  const links = [
    <Link aria-label="GitHub" href={process.env.NEXT_PUBLIC_GITHUB_URL!} target="_blank">
      <FontAwesomeIcon icon={faGithub} />
    </Link>
    ,
    <Link aria-label="GitLab" href={process.env.NEXT_PUBLIC_GITLAB_URL!} target="_blank">
      <FontAwesomeIcon icon={faGitlab} />
    </Link>
  ]

  return (
    <div className={`grid grid-cols-${links.length} gap-4`}>
      {links}
    </div>
  )
}
