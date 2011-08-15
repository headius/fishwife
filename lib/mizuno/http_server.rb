module Mizuno
    class HttpServer
        include_class 'org.eclipse.jetty.server.Server'
        include_class 'org.eclipse.jetty.servlet.ServletContextHandler'
        include_class 'org.eclipse.jetty.servlet.ServletHolder'
        include_class 'org.eclipse.jetty.server.nio.SelectChannelConnector'
        include_class 'org.eclipse.jetty.util.thread.QueuedThreadPool'
        include_class 'org.eclipse.jetty.servlet.DefaultServlet'

        #
        # Start up an instance of Jetty, running a Rack application.
        # Options can be any of the follwing, and are not
        # case-sensitive:
        #
        # :host::
        #     String specifying the IP address to bind to; defaults 
        #     to 0.0.0.0.
        #
        # :port::
        #     String or integer with the port to bind to; defaults 
        #     to 9292.
        #
        # FIXME: Clean up options hash (all downcase, all symbols)
        #
        def self.run(app, options = {})
            # The Jetty server
            @server = Server.new

            options = Hash[options.map { |o| 
                [ o[0].to_s.downcase.to_sym, o[1] ] }]

            # Thread pool
            thread_pool = QueuedThreadPool.new
            thread_pool.min_threads = 5
            thread_pool.max_threads = 50
            @server.set_thread_pool(thread_pool)

            # Connector
            connector = SelectChannelConnector.new
            connector.setPort(options[:port].to_i)
            connector.setHost(options[:host])
            @server.addConnector(connector)

            # Servlet context.
            context = ServletContextHandler.new(nil, "/", 
                ServletContextHandler::NO_SESSIONS)

            # The servlet itself.
            rack_servlet = RackServlet.new
            rack_servlet.rackup(app)
            holder = ServletHolder.new(rack_servlet)
            context.addServlet(holder, "/")

            # Add the context to the server and start.
            @server.set_handler(context)

            @server.stop_at_shutdown = true
            @server.start
        end

        def self.join
            @server.join if @server
        end

        #
        # Shuts down an embedded Jetty instance.
        #
        def self.stop
            @server.stop
        end
    end
end
