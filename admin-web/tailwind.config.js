/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT: "#A53A3E",
          dark: "#8B2E32",
          light: "#F5DEDE",
        },
        surface: "#FAFAFA",
        card: "#FFFFFF",
        input: "#F5F5F5",
        ink: {
          DEFAULT: "#212121",
          muted: "#757575",
          hint: "#BDBDBD",
        },
        line: "#EEEEEE",
        status: {
          submitted: "#1565C0",
          acknowledged: "#6A1B9A",
          inprogress: "#E65100",
          resolved: "#2E7D32",
          cancelled: "#757575",
        },
        semantic: {
          success: "#2E7D32",
          warning: "#F9A825",
          error: "#C62828",
          info: "#1565C0",
        },
      },
      fontFamily: {
        sans: [
          '"Plus Jakarta Sans"',
          "ui-sans-serif",
          "system-ui",
          "sans-serif",
        ],
      },
      boxShadow: {
        card: "0 1px 3px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04)",
      },
    },
  },
  plugins: [],
};
