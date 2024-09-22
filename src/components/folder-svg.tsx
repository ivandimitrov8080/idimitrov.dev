type FolderSvgProps = {
  preserveAspectRatio?: string
}
const FolderSvg = ({ preserveAspectRatio }: FolderSvgProps) => (
  <svg preserveAspectRatio={preserveAspectRatio ?? "xMidYMid meet"} className="w-full h-full" style={{ transform: "scaleX(-1)" }} viewBox="0 0 580 435">
    <defs>
      <linearGradient id="linear" x1="0%" y1="100%" x2="100%" y2="0%">
        <stop offset="0%" stopColor="#facc15" />
        <stop offset="50%" stopColor="#b91c1c" />
        <stop offset="100%" stopColor="#020617" />
      </linearGradient>
    </defs>
    <path
      className="fill-none"
      stroke="url(#linear)"
      d="
        M 25 0
        L 180 0
        C 180 0
          200 0
          230 30
        L 550 30
        S 580 30
          580 60
        L 580 400
        S 580 435
          550 435
        L 25 435
        S 0 435
          0 405
        L 0 25
        S 0 0
          30 0
        "
      style={{ strokeWidth: 3 }}
    />
  </svg>
);

export default FolderSvg;
