// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/vmemo_web.ex",
    "../lib/vmemo_web/**/*.*ex",
    "../lib/vmemo_web/**/*.{heex,sface}",
    "../priv/catalogue/**/*.{ex,sface}"
  ],
  theme: {
    extend: {
      colors: {
        brand: "#FD4F00",
      }
    },
  },
  daisyui: {
    themes: [
      {
        base: {
          "color-scheme": "light",

          // TODO: 需要吗？不需要可以删掉。
          neutral: "#586069", // 中性色

          "base-100": "rgb(245 245 245)", // 背景色
          "base-200": "rgb(229 229 229)", // 辅助背景色
          "base-300": "rgb(212 212 212)", // 边框色
          "base-content": "#24292e", // body 文本色

          accent: "#18181b", // 主要使用，但是不是 brand color, 例如提交按钮
          "accent-content": "#fafafa",

          info: "#0366d6", // 信息色（GitHub蓝）
          success: "#28a745", // 成功色
          warning: "#d73a49", // 警告色
          error: "#cb2431", // 错误色
          "error-content": "#ffffff", // 错误色文本

          "--rounded-box": "0.75rem", // 圆角盒子
          "--rounded-btn": "0.25rem", // 按钮圆角
          "--rounded-badge": "0.75rem", // 徽章圆角
          "--tab-radius": "0.5rem", // 选项卡圆角
          "--btn-focus-scale": "0.95", // scale transform of button when you focus on it FIXME: not working, ref: https://daisyui.com/docs/utilities/
        },
      },
    ],
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography"),
    require("tailwindcss-animate"),
    require("daisyui"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
      let values = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
          let name = path.basename(file, ".svg") + suffix
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) }
        })
      })
      matchComponents({
        "hero": ({ name, fullPath }) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          let size = theme("spacing.6")
          if (name.endsWith("-mini")) {
            size = theme("spacing.5")
          } else if (name.endsWith("-micro")) {
            size = theme("spacing.4")
          }
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "mask-repeat": "no-repeat",
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
            "width": size,
            "height": size
          }
        }
      }, { values })
    })
  ]
}
