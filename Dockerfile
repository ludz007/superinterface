############################################
# Stage 1: Build Stage
############################################
FROM node:18-alpine AS builder

# 1) Set working directory
WORKDIR /app

# 2) Copy package.json and pnpm lockfile
COPY package.json pnpm-lock.yaml ./

# 3) Install pnpm and dependencies
RUN npm install -g pnpm@latest
RUN pnpm install

# 4) Copy all source files
COPY . .

# 5) Generate Prisma client and run migrations
RUN pnpm prisma generate \
    && pnpm prisma migrate deploy

# 6) Build the Next.js application
RUN pnpm build


############################################
# Stage 2: Production Runtime Stage
############################################
FROM node:18-alpine

# 1) Create working directory in final image
WORKDIR /app

# 2) Copy only the built assets and node_modules from the builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./​.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json

# 3) Expose port 3000
EXPOSE 3000

# 4) Ensure NODE_ENV=production
ENV NODE_ENV=production

# 5) Final command to start the app
CMD ["pnpm", "start"]
