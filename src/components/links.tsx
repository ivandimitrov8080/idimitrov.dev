import GiteaSvg from "@/components/gitea-svg";
import { faGithub, faLinkedin, faUpwork } from "@fortawesome/free-brands-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import Link from "next/link";
import FolderSvg from "./folder-svg";

const Links = () => (
  <div className="grid w-max h-max grid-cols-2 grid-rows-2 gap-0 place-content-center absolute right-96 top-[35%] circle-gradient">
    <FolderSvg />
    <Link className="p-5 mr-[1px] bg-slate-950" aria-label="GitHub" href={process.env.NEXT_PUBLIC_GITHUB_URL || "https://github.com/ivandimitrov8080"} target="_blank">
      <FontAwesomeIcon className="w-14 h-14" icon={faGithub} />
    </Link>
    <Link className="p-5 bg-slate-950" aria-label="GitLab" href={process.env.NEXT_PUBLIC_GITEA_URL || "https://src.idimitrov.dev/ivandimitrov8080"} target="_blank">
      <GiteaSvg />
    </Link>
    <Link className="p-5 mr-[1px] mt-[1px] bg-slate-950" aria-label="LinkedIn" href={process.env.NEXT_PUBLIC_LINKEDIN_URL || "https://www.linkedin.com/in/devidimitrov"} target="_blank">
      <FontAwesomeIcon className="w-14 h-14" icon={faLinkedin} />
    </Link>
    <Link className="p-5 mt-[1px] bg-slate-950" aria-label="Upwork" href={process.env.NEXT_PUBLIC_UPWORK_URL || "https://www.upwork.com/freelancers/idimitrov"} target="_blank">
      <FontAwesomeIcon className="w-14 h-14" icon={faUpwork} />
    </Link>
  </div>
)

export default Links;
