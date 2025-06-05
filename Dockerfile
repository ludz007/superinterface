############################################
# Stage 1: Builder – install dependencies & build all packages
############################################
FROM node:18-alpine AS builder

# 1) Set the working directory to the repo root
WORKDIR /app

# 2) Copy only the files needed to install dependencies
#    (including turbo.json so npm knows about workspaces)
COPY package.json package-lock.json turbo.json ./

# 3) Install all dependencies (including devDependencies for each workspace)
#    This will populate node_modules for packages/react, packages/root-element, etc.
RUN npm install

# 4) Make tsup available globally, since some workspaces rely on it
RUN npm install -g tsup

# 5) Copy the rest of the repo to /app
COPY . .

# 6) Run the “build” script from the root (Turbo will build every workspace,
#    including @superinterface/react and @superinterface/root-element)
RUN npm run build


############################################
# Stage 2: Runner – copy only the production output & start Next.js
############################################
FROM node:18-alpine AS runner

# 1) Create a fresh working directory
WORKDIR /app

# 2) Copy only what’s needed for the Next.js app from the builder:
#    • node_modules for the app (Turbo places dependencies into packages/app/node_modules)
#    • the built .next/ folder for the app
#    • the public/ folder for the app
#    • the app’s package.json so “npm start” works
COPY --from=builder /app/packages/app/node_modules ./packages/app/node_modules
COPY --from=builder /app/packages/app/.next ./packages/app/.next
COPY --from=builder /app/packages/app/public ./packages/app/public
COPY --from=builder /app/packages/app/package.json ./packages/app/package.json

# 3) Switch into the app’s folder for runtime
WORKDIR /app/packages/app

# 4) Ensure we’re in production mode
ENV NODE_ENV=production

# 5) Expose port 3000 (Next.js default)
EXPOSE 3000

# 6) Start the Next.js server
CMD ["npm", "start"]
