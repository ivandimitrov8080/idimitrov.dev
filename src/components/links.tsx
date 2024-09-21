import GiteaSvg from "@/components/gitea-svg";
import { faGithub, faLinkedin, faUpwork } from "@fortawesome/free-brands-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import Link from "next/link";
import FolderSvg from "./folder-svg";

const Links = () => (
  <div className="relative h-full grid place-content-center">
    <FolderSvg />
    <div className="relative grid w-max h-max grid-cols-2 grid-rows-2 gap-0">
      <div className="absolute circle-gradient w-[1px] h-full left-1/2"></div>
      <div className="absolute circle-gradient w-full h-[1px] top-1/2"></div>
      <Link className="p-5" aria-label="GitHub" href={process.env.NEXT_PUBLIC_GITHUB_URL || "https://github.com/ivandimitrov8080"} target="_blank">
        <FontAwesomeIcon className="w-14 h-14" icon={faGithub} />
      </Link>
      <Link className="p-5" aria-label="GitLab" href={process.env.NEXT_PUBLIC_GITEA_URL || "https://src.idimitrov.dev/ivandimitrov8080"} target="_blank">
        <GiteaSvg />
      </Link>
      <Link className="p-5" aria-label="LinkedIn" href={process.env.NEXT_PUBLIC_LINKEDIN_URL || "https://www.linkedin.com/in/devidimitrov"} target="_blank">
        <FontAwesomeIcon className="w-14 h-14" icon={faLinkedin} />
      </Link>
      <Link className="p-5" aria-label="Upwork" href={process.env.NEXT_PUBLIC_UPWORK_URL || "https://www.upwork.com/freelancers/idimitrov"} target="_blank">
        <FontAwesomeIcon className="w-14 h-14" icon={faUpwork} />
      </Link>
    </div>
  </div>
);

export default Links;
