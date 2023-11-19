import { faGithub, faGitlab } from "@fortawesome/free-brands-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import Link from "next/link";

const Home = () =>
  <div className="grid w-full h-full place-content-center">
    <div className={"grid grid-cols-2 gap-4 place-content-center"}>
      <Link aria-label="GitHub" href={process.env.NEXT_PUBLIC_GITHUB_URL!} target="_blank">
        <FontAwesomeIcon className="w-14 h-14" icon={faGithub} />
      </Link>
      <Link aria-label="GitLab" href={process.env.NEXT_PUBLIC_GITLAB_URL!} target="_blank">
        <FontAwesomeIcon className="w-14 h-14" icon={faGitlab} />
      </Link>
    </div>
  </div>

export default Home;
