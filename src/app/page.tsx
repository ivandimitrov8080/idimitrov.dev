import GiteaSvg from "@/components/gitea-svg";
import { faGithub, faGitlab, faUpwork } from "@fortawesome/free-brands-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import Link from "next/link";

const Home = () => (
  <div className="grid w-full h-full place-content-center">
    <div className={"grid grid-cols-2 gap-4 place-content-center"}>
      <Link aria-label="GitLab" href={process.env.NEXT_PUBLIC_GITEA_URL || "https://src.idimitrov.dev/ivan"} target="_blank">
        <GiteaSvg />
      </Link>
      <Link aria-label="GitHub" href={process.env.NEXT_PUBLIC_GITHUB_URL || "https://github.com/ivandimitrov8080"} target="_blank">
        <FontAwesomeIcon className="w-14 h-14" icon={faGithub} />
      </Link>
      <Link aria-label="GitLab" href={process.env.NEXT_PUBLIC_GITLAB_URL || "https://gitlab.com/ivandimitrov8080"} target="_blank">
        <FontAwesomeIcon className="w-14 h-14" icon={faGitlab} />
      </Link>
      <Link aria-label="Upwork" href={process.env.NEXT_PUBLIC_UPWORK_URL || "https://www.upwork.com/freelancers/idimitrov"} target="_blank">
        <FontAwesomeIcon className="w-14 h-14" icon={faUpwork} />
      </Link>
    </div>
  </div>
);

export default Home;
