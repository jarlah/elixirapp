# Extend from the official Elixir image
FROM elixir:latest

# Create app directory and copy the Elixir projects into it
RUN mkdir /app
COPY . /app
WORKDIR /app

# Install hex package manager
# By using --force, we don’t need to type “Y” to confirm the installation
RUN mix local.hex --force

# Compile the project
RUN mix do compile

# If running this in kubernetes use env variables. Out of scope
CMD ["mix","eve_online.get_object_names","datasource=tranquility","region_id=10000002","order_type=all"]