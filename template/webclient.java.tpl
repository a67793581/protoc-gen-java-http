package {{.PackageName}};

import java.io.IOException;
import java.util.*;
import okhttp3.*;

import com.google.protobuf.Message;
import com.google.protobuf.util.JsonFormat;


{{- range .Imports}}
import {{.}};
{{- end}}

public class {{.ServiceName}} {

    private final OkHttpClient httpClient;
    private final String baseUrl;

    public {{.ServiceName}}(OkHttpClient httpClient, String baseUrl) {
        this.httpClient = httpClient;
        this.baseUrl = baseUrl;
    }

    private <T extends Message, K extends Message> T jsonPostCall(String baseUrl, K request, T.Builder responseBuilder) throws IOException {
        return jsonPostCall(baseUrl, request, responseBuilder, null);
    }

    private <T extends Message, K extends Message> T jsonPostCall(String baseUrl, K request, T.Builder responseBuilder, Headers headers) throws IOException {
        Request.Builder requestBuilder = new Request.Builder()
                .url(baseUrl)
                .post(RequestBody.create(JsonFormat.printer().alwaysPrintFieldsWithNoPresence().print(request),
                        MediaType.parse("application/json")));
        
        if (headers != null) {
            requestBuilder.headers(headers);
        }
        
        try (Response response = httpClient.newCall(requestBuilder.build()).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Unexpected code " + response);
            }

            String responseBody = response.body().string();
            if (responseBody == null || responseBody.isBlank()) {
                return null;
            }
            JsonFormat.parser().merge(responseBody, responseBuilder);
            @SuppressWarnings("unchecked")
            T result = (T) responseBuilder.build();
            return result;
        }
    }

{{- range .HttpRuleMap }}
    {{- if eq .HttpMethod "Post" }}
    {{- "\n\t //"}}{{ .Method.Comment -}} {{.HttpMethod}}
    {{- "\n\t" }}public {{ .ResponseBody.Type }} {{.Method.Name}}({{ .RequestMessage.Type }} {{ .RequestMessage.Name -}}
    , Headers headers) throws IOException {
        {{ .ResponseBody.Type }}.Builder res = {{ .ResponseBody.Type }}.newBuilder();
        return this.jsonPostCall(baseUrl + "{{.HttpPath}}", {{ .RequestMessage.Name }}, res, headers);
    }
    {{- end }}
{{- end }}

{{- range .HttpRuleMap }}

    {{- if eq .HttpMethod "Post" }}
    {{- "\n\t //"}}{{ .Method.Comment -}} {{.HttpMethod}}
    {{- "\n\t" }}public {{ .ResponseBody.Type }} {{.Method.Name}}({{ .RequestMessage.Type }} {{ .RequestMessage.Name -}}
    ) throws IOException {
        {{ .ResponseBody.Type }}.Builder res = {{ .ResponseBody.Type }}.newBuilder();
        return this.jsonPostCall(baseUrl + "{{.HttpPath}}", {{ .RequestMessage.Name }}, res);
    }
    {{- end }}
{{- end }}
}