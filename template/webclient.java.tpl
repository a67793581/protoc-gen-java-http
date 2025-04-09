package {{.PackageName}};

import java.io.IOException;
import java.util.*;

import org.apache.commons.lang3.StringUtils;

import com.google.protobuf.Message;
import com.google.protobuf.util.JsonFormat;

import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

{{- range .Imports}}
import {{.}};
{{- end}}

public class {{.ServiceName}}WebClient {

    private final OkHttpClient httpClient;
    private final String baseUrl;

    public {{.ServiceName}}WebClient(OkHttpClient httpClient, String baseUrl) {
        this.httpClient = httpClient;
        this.baseUrl = baseUrl;
    }

    private <T extends Message, K extends Message> T jsonPostCall(String baseUrl, K request, T.Builder responseBuilder) throws IOException {

        String json = JsonFormat.printer().includingDefaultValueFields().print(request);
        RequestBody body = RequestBody.create(json, MediaType.parse("application/json"));

        Request httpRequest = new Request.Builder()
            .url(baseUrl)
            .post(body)
            .build();

        try (Response response = httpClient.newCall(httpRequest).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Unexpected code " + response);
            }

            String responseBody = response.body().string();
            if (StringUtils.isBlank(responseBody)){
                return null;
            }

            JsonFormat.parser().merge(responseBody, responseBuilder);
            return (T) responseBuilder.build();
        }
    }

    private String getCurrentMethodName() {
        return Thread.currentThread().getStackTrace()[2].getMethodName();
    }

{{ range .HttpRuleMap }}
    {{- "\n\t //"}}{{ .Method.Comment -}} {{.HttpMethod}}
    {{- "\n\t" }}public {{ .ResponseBody.Type }} {{.Method.Name}}({{ .RequestMessage.Type }} {{ .RequestMessage.Name -}}
    ) throws IOException {
    {{- if eq .HttpMethod "Post" }}
        {{ .ResponseBody.Type }}.Builder res = {{ .ResponseBody.Type }}.newBuilder();
        return this.jsonPostCall(baseUrl + "{{.HttpPath}}", {{ .RequestMessage.Name }}, res);
    {{- end }}
    {{- if ne .HttpMethod "Post" }}
        return null;
    {{- end }}
    }
{{ end }}

}