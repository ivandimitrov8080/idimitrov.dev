import { CSSProperties } from "react";

type Props = {
  count: number;
};


type StarProps = {
  solo?: boolean;
}

const Star = ({ solo }: StarProps) => {
  const randomRgba = (alpha: number) => {
    return `rgba(${Math.random() * 255}, ${Math.random() * 255}, ${Math.random() * 255}, ${alpha})`
  }
  const radius = `${Math.random() * 7}px`
  let style: CSSProperties = {
    background: `radial-gradient(circle, ${randomRgba(0.6)} 0%, ${randomRgba(0)} 100%)`,
    width: radius,
    height: radius,
  };
  if (solo) {
    const x = Math.floor(Math.random() * 100), y = Math.floor(Math.random() * 100);
    style = {
      ...style,
      left: `${x}%`,
      top: `${y}%`
    }
  }
  return (
    <div
      style={style}
      className="absolute z-10">
    </div>
  )
}

const SpinningStar = () => {
  const r = .1 + Math.random() * 1337
  const containerRadius = `${r}px`
  const duration = Math.floor(r) / 100;
  const x = Math.floor(Math.random() * 100), y = Math.floor(Math.random() * 100);
  const animation = Math.random() > .5 ? "spinner" : "spinner-reverse"
  return (
    <div
      style={{
        left: `${x}%`,
        top: `${y}%`,
        width: containerRadius,
        height: containerRadius,
        animation: `${animation} ${duration}s linear infinite`
      }}
      className="absolute z-10 max-w-full max-h-full">
      <Star />
    </div>
  )
}
const Stars = ({ count }: Props) => {
  return (
    <div className="absolute w-screen h-screen overflow-hidden">
      {Array.from({ length: count }).map((_it, i) => {
        return i % 4 === 0 ? <SpinningStar key={i} /> : <Star key={i} solo={true} />
      })}
    </div>
  );
};

export default Stars;
