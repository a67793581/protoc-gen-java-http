package {{.PackageName}};

import java.io.IOException;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.google.protobuf.Message;
import com.google.protobuf.util.JsonFormat;

import cn.hutool.core.collection.CollectionUtil;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

{{- range .Imports}}
import {{.}};
{{- end}}

@Configuration
public class {{.ServiceName}}WebClient {

    @Bean
    public {{.ServiceName}}WebClient buildWebClient() {

        return new {{.ServiceName}}WebClient(webClient);
    }

    private final OkHttpClient httpClient;
    private final String baseUrl;

    public {{.ServiceName}}WebClient(OkHttpClient httpClient, String baseUrl) {
        this.httpClient = httpClient;
        this.baseUrl = baseUrl;
    }

    {{ range .HttpRuleMap }}
        {{ if .Method.HasComment }}
           {{- "\n\t //"}} {{ .Method.Comment -}}
        {{ end }}
        {{- "\n\t" }} public Mono<{{ .ResponseBody.Type }}> {{.Method.Name}}({{ .RequestMessage.Type }} {{ .RequestMessage.Name -}}
        ) {
            // 构建请求
            RequestBodySpec request = webClient.method(HttpMethod.valueOf("{{ .HttpMethod }}"))
                    .uri(uriBuilder -> {
                        {{ if .HasPathParams }}
                            {{ range .PathParams }}
                                uriBuilder = uriBuilder.pathSegment("{" + "{{ .Name }}" + "}");
                            {{ end }}
                        {{ end }}
                        {{ if .HasQueryParams }}
                            {{ range .QueryParams }}
                                uriBuilder = uriBuilder.queryParam("{{ .Name }}", {{ .Name }});
                            {{ end }}
                        {{ end }}
                        return uriBuilder.build(
                            {{ if .HasPathParams }}
                                {{ range .PathParams }}
                                    {{ .Name }},
                                {{ end }}
                            {{ end }}
                        );
                    });

            {{ if .HasRequestBody }}
                // 添加请求体
                request = request.bodyValue({{ .RequestMessage.Name }}.get{{ .RequestBody.Name }}());
            {{ end }}

            // 发送请求并处理响应
            return request.retrieve()
                    .bodyToMono(new ParameterizedTypeReference<{{ .ResponseBody.Type }}>() {})
                    .flatMap(resp -> {
                        // 处理响应
                        if (resp.getCode() == 200) {
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