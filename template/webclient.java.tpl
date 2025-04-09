package {{.PackageName}};

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.reactive.function.client.WebClient;
import io.netty.channel.ChannelOption;
import io.netty.handler.timeout.ReadTimeoutHandler;
import io.netty.handler.timeout.WriteTimeoutHandler;
import reactor.netty.Connection;
import reactor.netty.http.client.HttpClient;
import reactor.netty.tcp.TcpClient;
import reactor.netty.resources.ConnectionProvider;

import java.time.Duration;
import reactor.core.publisher.Mono;

{{- range .Imports}}
import {{.}};
{{- end}}

@Configuration
public class {{.ServiceName}}WebClient {

    @Bean
    public {{.ServiceName}}WebClient {{.ServiceName}}WebClient() {
        // 设置连接池，最大连接数为 50，最大空闲时间 30 秒
        ConnectionProvider provider = ConnectionProvider.builder("{{.ServiceName}}_client")
                .maxConnections(50)  // 最大连接数
                .maxIdleTime(Duration.ofSeconds(30))  // 最大空闲时间
                .maxLifeTime(Duration.ofSeconds(60))  // 最大生存时间
                .build();

        // 创建 TcpClient 并配置连接池
        TcpClient tcpClient = TcpClient.create(provider)
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 5000) // 连接超时
                .doOnConnected(connection ->
                        connection.addHandlerLast(new ReadTimeoutHandler(60))  // 读取超时
                                .addHandlerLast(new WriteTimeoutHandler(60))); // 写入超时

        // 创建 HttpClient
        HttpClient httpClient = HttpClient.from(tcpClient)
                .responseTimeout(Duration.ofSeconds(60));  // 响应超时

        // 使用 ReactorClientHttpConnector 作为连接器
        WebClient webClient = WebClient.builder()
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .codecs(configurer -> configurer.defaultCodecs()
                        .maxInMemorySize(16 * 1024 * 1024))  // 设置缓存限制为 16MB
                .build();

        // 返回自定义的 WebClientWrapper 实例
        return new {{.ServiceName}}WebClient(webClient);
    }

    private final WebClient webClient;

    public {{.ServiceName}}WebClient(WebClient webClient) {
        this.webClient = webClient;
    }

    {{ range .HttpRuleMap }}
        {{ if .Method.HasComment }}
            // {{ .Method.Comment }}
        {{ end }}
        public Mono<{{ .ResponseBody.Type }}> {{ .Method.Name }}(
            {{ $len := (len .Params) }}
            {{ if gt $len 1 }}
                {{ range $index, $param := .Params }}
                    {{ if gt $index 0 }},{{ end }}
                    {{ $param.Annotation}} {{ $param.Type }} {{ $param.Name }}
                {{ end }}
            {{ else }}
                {{ range $index, $param := .Params }}
                    {{ if gt $index 0 }},{{ end }}
                    {{ $param.Annotation}} {{ $param.Type }} {{ $param.Name }}
                {{ end }}
            {{ end }}
        ) {
            {{ if .HasRequestBody }}
                {{ if or .PathParams .QueryParams }}
                    {{ if not .IsWildcards }}
                        {{ $rm := .RequestMessage }}{{ $rm.Type }} {{ $rm.Name }} = {{ $rm.Type }}.newBuilder()
                        {{ range .PathParams }}
                            .set{{ .Name}}({{ .Name }})
                        {{ end }}
                        {{ range .QueryParams }}
                            .set{{ .Name}}({{ .Name }})
                        {{ end }}
                        .set{{ .RequestBody.Name}}({{ .RequestBody.Name }})
                        .build();
                    {{ end }}
                {{ end }}
            {{ else }}
                {{ if or .PathParams .QueryParams }}
                    {{ $rm := .RequestMessage }}{{ $rm.Type }} {{ $rm.Name }} = {{ $rm.Type }}.newBuilder()
                    {{ range .PathParams }}
                        .set{{ .Name}}({{ .Name }})
                    {{ end }}
                    {{ range .QueryParams }}
                        .set{{ .Name}}({{ .Name }})
                    {{ end }}
                    .build();
                {{ else }}
                    {{ $rm := .RequestMessage }}{{ $rm.Type }} {{ $rm.Name }} = {{ $rm.Type }}.newBuilder().build();
                {{ end }}
            {{ end }}

            // 构建请求
            WebClient.RequestBodySpec request = webClient.method(HttpMethod.valueOf("{{ .HttpMethodMapping }}"))
                    .uri(uriBuilder -> {
                        {{ if or .PathParams .QueryParams }}
                            {{ range .PathParams }}
                                uriBuilder = uriBuilder.pathSegment("{{ .Name }}");
                            {{ end }}
                            {{ range .QueryParams }}
                                uriBuilder = uriBuilder.queryParam("{{ .Name }}", {{ .Name }});
                            {{ end }}
                        {{ end }}
                        return uriBuilder.build();
                    });

            // 添加请求体
            {{ if .HasRequestBody }}
                request = request.bodyValue({{ .RequestBody.Name }});
            {{ end }}

            // 发送请求并处理响应
            return request.retrieve()
                    .bodyToMono(new ParameterizedTypeReference<{{ .ResponseBody.Type }}>() {})
                    .flatMap(resp -> {
                        // 处理响应
                        // 假设 resp 是 ApiResponse 类型，且包含 getCode() 和 getData() 方法
                        if (resp.getCode() == 200) {
                            // 处理 data 字段
                            {{ .ResponseBody.Type }} data = resp.getData();
                            if (data != null) {
                                return Mono.just(data);
                            }
                        } else {
                            log.error("{{ .Method.Name }} code != 200: {}", resp);
                        }
                        return Mono.empty();
                    })
                    .doOnError(error -> log.error("{{ .Method.Name }} Error occurred: {}", error.getMessage()));
        }
    {{ end }}

}
