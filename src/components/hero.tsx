import Link from "next/link";
import Links from "./links";

const Hero = () => (
  <div className="grid px-14 py-48 gap-12">
    <div className="w-1/2 grid gap-6">
      <div>
        <p className="text-3xl text-[#FB923C]">Software Developer</p>
        <p className="text-8xl text-white capitalize">Full stack web development</p>
        <p className="text-8xl capitalize text-transparent font-bold bg-gradient-to-br from-transparent via-teal-400 to-yellow-400 bg-clip-text">optimized</p>
      </div>
      <Link aria-label="Cases" href="/cases" target="_blank" className="w-max">
        <svg width="224" height="56" viewBox="0 0 224 56" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path fillRule="evenodd" clipRule="evenodd" d="M0 28C0 12.536 12.536 0 28 0H134C142.295 0 149.747 3.60698 154.875 9.33804C157.255 11.9985 160.452 14 164.022 14H165.978C169.548 14 172.745 11.9985 175.125 9.33804C180.253 3.60698 187.705 0 196 0C211.464 0 224 12.536 224 28C224 43.464 211.464 56 196 56C187.705 56 180.253 52.393 175.125 46.662C172.745 44.0015 169.548 42 165.978 42H164.022C160.452 42 157.255 44.0015 154.875 46.662C149.747 52.393 142.295 56 134 56H28C12.536 56 0 43.464 0 28Z" fill="url(#paint0_linear_117_87)" />
          <path d="M200 24.4L191.1 33.3C190.917 33.4833 190.683 33.575 190.4 33.575C190.117 33.575 189.883 33.4833 189.7 33.3C189.517 33.1167 189.425 32.8833 189.425 32.6C189.425 32.3167 189.517 32.0833 189.7 31.9L198.6 23H191C190.717 23 190.479 22.9042 190.287 22.7125C190.096 22.5208 190 22.2833 190 22C190 21.7167 190.096 21.4792 190.287 21.2875C190.479 21.0958 190.717 21 191 21H201C201.283 21 201.521 21.0958 201.712 21.2875C201.904 21.4792 202 21.7167 202 22V32C202 32.2833 201.904 32.5208 201.712 32.7125C201.521 32.9042 201.283 33 201 33C200.717 33 200.479 32.9042 200.287 32.7125C200.096 32.5208 200 32.2833 200 32V24.4Z" fill="white" />
          <path d="M66.3111 26.1662H64.3168C64.2401 25.7401 64.0973 25.3651 63.8885 25.0412C63.6797 24.7173 63.424 24.4425 63.1214 24.2166C62.8189 23.9908 62.4801 23.8203 62.1051 23.7053C61.7344 23.5902 61.3402 23.5327 60.9226 23.5327C60.1683 23.5327 59.4929 23.7223 58.8963 24.1016C58.304 24.4808 57.8352 25.0369 57.4901 25.7699C57.1491 26.5028 56.9787 27.3977 56.9787 28.4545C56.9787 29.5199 57.1491 30.419 57.4901 31.152C57.8352 31.8849 58.3061 32.4389 58.9027 32.8139C59.4993 33.1889 60.1705 33.3764 60.9162 33.3764C61.3295 33.3764 61.7216 33.321 62.0923 33.2102C62.4673 33.0952 62.8061 32.9268 63.1087 32.7053C63.4112 32.4837 63.6669 32.2131 63.8757 31.8935C64.0888 31.5696 64.2358 31.1989 64.3168 30.7812L66.3111 30.7876C66.2045 31.4311 65.9979 32.0234 65.6911 32.5646C65.3885 33.1016 64.9986 33.5661 64.5213 33.9581C64.0483 34.3459 63.5071 34.6463 62.8977 34.8594C62.2884 35.0724 61.6236 35.179 60.9034 35.179C59.7699 35.179 58.7599 34.9105 57.8736 34.3736C56.9872 33.8324 56.2884 33.0589 55.777 32.0533C55.2699 31.0476 55.0163 29.848 55.0163 28.4545C55.0163 27.0568 55.272 25.8572 55.7834 24.8558C56.2947 23.8501 56.9936 23.0788 57.88 22.5419C58.7663 22.0007 59.7741 21.7301 60.9034 21.7301C61.598 21.7301 62.2457 21.8303 62.8466 22.0305C63.4517 22.2266 63.995 22.5163 64.4766 22.8999C64.9581 23.2791 65.3565 23.7436 65.6719 24.2933C65.9872 24.8388 66.2003 25.4631 66.3111 26.1662ZM71.3784 35.2173C70.7562 35.2173 70.1937 35.1023 69.6909 34.8722C69.188 34.6378 68.7896 34.299 68.4956 33.8558C68.2058 33.4126 68.0609 32.8693 68.0609 32.2259C68.0609 31.6719 68.1674 31.2159 68.3805 30.858C68.5936 30.5 68.8812 30.2166 69.2434 30.0078C69.6056 29.799 70.0105 29.6413 70.4579 29.5348C70.9054 29.4283 71.3613 29.3473 71.8258 29.2919C72.4139 29.2237 72.8912 29.1683 73.2576 29.1257C73.6241 29.0788 73.8904 29.0043 74.0566 28.902C74.2228 28.7997 74.3059 28.6335 74.3059 28.4034V28.3587C74.3059 27.8004 74.1483 27.3679 73.8329 27.0611C73.5218 26.7543 73.0574 26.6009 72.4395 26.6009C71.796 26.6009 71.2889 26.7436 70.9181 27.0291C70.5517 27.3104 70.2981 27.6236 70.1575 27.9688L68.3613 27.5597C68.5744 26.9631 68.8855 26.4815 69.2946 26.1151C69.7079 25.7443 70.1831 25.4759 70.72 25.3097C71.2569 25.1392 71.8216 25.054 72.4139 25.054C72.8059 25.054 73.2214 25.1009 73.6603 25.1946C74.1035 25.2841 74.5169 25.4503 74.9004 25.6932C75.2882 25.9361 75.6056 26.2834 75.8528 26.7351C76.1 27.1825 76.2235 27.7642 76.2235 28.4801V35H74.3571V33.6577H74.2804C74.1568 33.9048 73.9714 34.1477 73.7243 34.3864C73.4771 34.625 73.1596 34.8232 72.7718 34.9808C72.3841 35.1385 71.9196 35.2173 71.3784 35.2173ZM71.7939 33.6832C72.3223 33.6832 72.774 33.5788 73.149 33.37C73.5282 33.1612 73.8159 32.8885 74.0119 32.5518C74.2122 32.2109 74.3123 31.8466 74.3123 31.4588V30.1932C74.2441 30.2614 74.112 30.3253 73.916 30.3849C73.7243 30.4403 73.5048 30.4893 73.2576 30.532C73.0105 30.5703 72.7697 30.6065 72.5353 30.6406C72.301 30.6705 72.1049 30.696 71.9473 30.7173C71.5765 30.7642 71.2377 30.843 70.9309 30.9538C70.6284 31.0646 70.3855 31.2244 70.2022 31.4332C70.0233 31.6378 69.9338 31.9105 69.9338 32.2514C69.9338 32.7244 70.1085 33.0824 70.4579 33.3253C70.8074 33.5639 71.2527 33.6832 71.7939 33.6832ZM86.1264 27.5788L84.3942 27.8857C84.3217 27.6641 84.2067 27.4531 84.049 27.2528C83.8956 27.0526 83.6868 26.8885 83.4226 26.7607C83.1584 26.6328 82.8281 26.5689 82.4318 26.5689C81.8906 26.5689 81.4389 26.6903 81.0767 26.9332C80.7145 27.1719 80.5334 27.4808 80.5334 27.8601C80.5334 28.1882 80.6548 28.4524 80.8977 28.6527C81.1406 28.853 81.5327 29.017 82.0739 29.1449L83.6335 29.5028C84.5369 29.7116 85.2102 30.0334 85.6534 30.468C86.0966 30.9027 86.3182 31.4673 86.3182 32.1619C86.3182 32.75 86.1477 33.2741 85.8068 33.7344C85.4702 34.1903 84.9993 34.5483 84.3942 34.8082C83.7933 35.0682 83.0966 35.1982 82.304 35.1982C81.2045 35.1982 80.3075 34.9638 79.6129 34.495C78.9183 34.022 78.4922 33.3509 78.3345 32.4815L80.1818 32.2003C80.2969 32.6818 80.5334 33.0462 80.8913 33.2933C81.2493 33.5362 81.7159 33.6577 82.2912 33.6577C82.9176 33.6577 83.4183 33.5277 83.7933 33.2678C84.1683 33.0036 84.3558 32.6818 84.3558 32.3026C84.3558 31.9957 84.2408 31.7379 84.0107 31.5291C83.7848 31.3203 83.4375 31.1626 82.9688 31.0561L81.3068 30.6918C80.3906 30.483 79.7131 30.1506 79.2741 29.6946C78.8395 29.2386 78.6222 28.6612 78.6222 27.9624C78.6222 27.3828 78.7841 26.8757 79.108 26.4411C79.4318 26.0064 79.8793 25.6676 80.4503 25.4247C81.0213 25.1776 81.6754 25.054 82.4126 25.054C83.4737 25.054 84.3089 25.2841 84.9183 25.7443C85.5277 26.2003 85.9304 26.8118 86.1264 27.5788ZM92.6511 35.1982C91.6838 35.1982 90.8507 34.9915 90.1518 34.5781C89.4572 34.1605 88.9203 33.5746 88.541 32.8203C88.166 32.0618 87.9785 31.1733 87.9785 30.1548C87.9785 29.1491 88.166 28.2628 88.541 27.4957C88.9203 26.7287 89.4487 26.13 90.1262 25.6996C90.8081 25.2692 91.6049 25.054 92.5169 25.054C93.0708 25.054 93.6078 25.1456 94.1277 25.3288C94.6475 25.5121 95.1142 25.7997 95.5275 26.1918C95.9409 26.5838 96.2669 27.093 96.5055 27.7195C96.7441 28.3416 96.8635 29.098 96.8635 29.9886V30.6662H89.0588V29.2344H94.9906C94.9906 28.7315 94.8883 28.2862 94.6838 27.8984C94.4792 27.5064 94.1916 27.1974 93.8208 26.9716C93.4544 26.7457 93.024 26.6328 92.5297 26.6328C91.9927 26.6328 91.524 26.7649 91.1234 27.0291C90.7271 27.2891 90.4203 27.63 90.2029 28.0518C89.9899 28.4695 89.8833 28.9233 89.8833 29.4134V30.532C89.8833 31.1882 89.9984 31.7464 90.2285 32.2067C90.4629 32.6669 90.7889 33.0185 91.2065 33.2614C91.6241 33.5 92.112 33.6193 92.6703 33.6193C93.0325 33.6193 93.3627 33.5682 93.661 33.4659C93.9593 33.3594 94.2172 33.2017 94.4345 32.9929C94.6518 32.7841 94.818 32.5263 94.9331 32.2195L96.742 32.5455C96.5971 33.0781 96.3372 33.5447 95.9622 33.9453C95.5914 34.3416 95.1248 34.6506 94.5623 34.8722C94.0041 35.0895 93.367 35.1982 92.6511 35.1982ZM106.341 27.5788L104.609 27.8857C104.537 27.6641 104.422 27.4531 104.264 27.2528C104.11 27.0526 103.902 26.8885 103.637 26.7607C103.373 26.6328 103.043 26.5689 102.647 26.5689C102.105 26.5689 101.654 26.6903 101.292 26.9332C100.929 27.1719 100.748 27.4808 100.748 27.8601C100.748 28.1882 100.87 28.4524 101.113 28.6527C101.355 28.853 101.748 29.017 102.289 29.1449L103.848 29.5028C104.752 29.7116 105.425 30.0334 105.868 30.468C106.311 30.9027 106.533 31.4673 106.533 32.1619C106.533 32.75 106.363 33.2741 106.022 33.7344C105.685 34.1903 105.214 34.5483 104.609 34.8082C104.008 35.0682 103.311 35.1982 102.519 35.1982C101.419 35.1982 100.522 34.9638 99.8278 34.495C99.1332 34.022 98.707 33.3509 98.5494 32.4815L100.397 32.2003C100.512 32.6818 100.748 33.0462 101.106 33.2933C101.464 33.5362 101.931 33.6577 102.506 33.6577C103.132 33.6577 103.633 33.5277 104.008 33.2678C104.383 33.0036 104.571 32.6818 104.571 32.3026C104.571 31.9957 104.456 31.7379 104.225 31.5291C104 31.3203 103.652 31.1626 103.184 31.0561L101.522 30.6918C100.605 30.483 99.9279 30.1506 99.489 29.6946C99.0543 29.2386 98.837 28.6612 98.837 27.9624C98.837 27.3828 98.9989 26.8757 99.3228 26.4411C99.6467 26.0064 100.094 25.6676 100.665 25.4247C101.236 25.1776 101.89 25.054 102.627 25.054C103.689 25.054 104.524 25.2841 105.133 25.7443C105.743 26.2003 106.145 26.8118 106.341 27.5788Z" fill="white" />
          <defs>
            <linearGradient id="paint0_linear_117_87" x1="54.6117" y1="-13.6529" x2="80.9647" y2="91.7588" gradientUnits="userSpaceOnUse">
              <stop stopColor="#020617" />
              <stop offset="0.5" stopColor="#B91C1C" />
              <stop offset="1" stopColor="#FACC15" />
            </linearGradient>
          </defs>
        </svg>
      </Link>
    </div>
    <Links />
  </div>
)

export default Hero;
