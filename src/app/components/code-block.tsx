"use client"
import { faCheck, faCopy } from "@fortawesome/free-solid-svg-icons"
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome"
import { ReactNode, useState } from "react"

type Props = {
  className?: string
  children?: ReactNode
}

const getText = (node: any) => {
  const props = node.props
  if (!props) {
    return node
  }
  const c = props.children
  return typeof c === "string" ? c : c.map(getText).join("")
}

const CodeBlock = ({ className, children }: Props) => {
  const [visible, setVisible] = useState("invisible")
  return (
    <div style={{ position: 'relative' }}>
      <button
        className="absolute top-5 right-5"
        onClick={() => {
          navigator.clipboard.writeText(getText(children))
          setVisible("visible")
          setTimeout(() => setVisible("invisible"), 1000)
        }}
      >
        <span className={`${visible} absolute bottom-5 left-5`}><FontAwesomeIcon className="text-green-400" icon={faCheck} /></span>
        <FontAwesomeIcon icon={faCopy} />
      </button>
      <pre className={`${className || ""}`}>{children}</pre>
    </div>
  )
}

export default CodeBlock;
