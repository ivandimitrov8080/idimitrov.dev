import { faGithub, faGitlab } from "@fortawesome/free-brands-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import Link from "next/link";

export default function Links() {

  return (
    <div className="grid w-full h-full place-content-center">
      <div className={"grid grid-cols-2 gap-4 place-content-center"}>
        <Link aria-label="GitHub" href={process.env.NEXT_PUBLIC_GITHUB_URL!} target="_blank">
          <FontAwesomeIcon icon={faGithub} />
        </Link>
        <Link aria-label="GitLab" href={process.env.NEXT_PUBLIC_GITLAB_URL!} target="_blank">
          <FontAwesomeIcon icon={faGitlab} />
        </Link>
      </div>
    </div>
  )
}
