import { faEnvelope } from "@fortawesome/free-solid-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

export default function Contact() {

  const email = "ivan@idimitrov.dev";

  return (
    <div className="w-full h-full p-2 grid place-content-center">
      <div className="flex flex-row gap-4">
        <a href={`mailto:${email}`}><FontAwesomeIcon icon={faEnvelope}/></a>
      </div>
    </div>
  )
}
