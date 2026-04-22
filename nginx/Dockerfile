# Build stage for frontend
FROM node:18 AS frontend-build
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ ./
# Create .env file for frontend build
RUN echo "VITE_BACKEND_URL=http://localhost:4000" > .env && \
    echo "VITE_CURRENCY=$" >> .env
RUN npm run build

# Build stage for admin
FROM node:18 AS admin-build
WORKDIR /app/admin
COPY admin/package*.json ./
RUN npm install
COPY admin/ ./
# Create .env file for admin build
RUN echo "VITE_BACKEND_URL=http://localhost:4000" > .env && \
    echo "VITE_CURRENCY=$" >> .env
RUN npm run build

# Final nginx stage
FROM nginx:alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy built static files
COPY --from=frontend-build /app/frontend/dist /usr/share/nginx/html/frontend
COPY --from=admin-build /app/admin/dist /usr/share/nginx/html/admin

# Copy nginx config
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80 8080

CMD ["nginx", "-g", "daemon off;"]