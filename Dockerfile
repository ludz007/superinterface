############################################
# Stage 1: “builder” — install & compile monorepo + Next.js example
############################################
FROM node:18-alpine AS builder

# 1) Work from /app in the build container
WORKDIR /app

# 2) Copy only the root package files & turbo.json
#    so that npm can install all workspaces without having to copy everything first.
COPY package.json package-lock.json turbo.json ./

# 3) Install _all_ dependencies (including devDependencies).
#    This populates node_modules for every workspace under /packages.
RUN npm install

# 4) Copy the rest of your monorepo into the container:
#    • packages/ (react, javascript, root-element, etc.)
#    • examples/next (the Next.js app)
COPY . .

# 5) Build every workspace via Turbo (this will compile @superinterface/react, @superinterface/root-element, etc.)
RUN npm run build

# 6) Switch into the Next.js example folder
WORKDIR /app/examples/next

# 7) Install ONLY the example’s dependencies (this reads examples/next/package.json & examples/next/package-lock.json)
RUN npm install

# 8) Build the Next.js example. 
#    This creates examples/next/.next and prepares it for production.
RUN npm run build


############################################
# Stage 2: “runner” — copy over only what the Next.js app needs at runtime
############################################
FROM node:18-alpine AS runner

# 1) Create a fresh working directory for the final image
WORKDIR /app

# 2) Copy the example’s production node_modules, the built .next folder, and public assets from “builder”
COPY --from=builder /app/examples/next/node_modules ./examples/next/node_modules
COPY --from=builder /app/examples/next/.next     ./examples/next/.next
COPY --from=builder /app/examples/next/public    ./examples/next/public
COPY --from=builder /app/examples/next/package.json ./examples/next/package.json

# 3) Switch into the Next.js example’s folder
WORKDIR /app/examples/next

# 4) Ensure we run in production mode
ENV NODE_ENV=production

# 5) Expose Next.js’s default port
EXPOSE 3000

# 6) Start the Next.js server
CMD ["npm", "start"]
