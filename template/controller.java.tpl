package {{.PackageName}};

import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.web.bind.annotation.*;
import java.util.List;
{{- range .Imports}}
import {{.}};
{{- end}}

@RestController
@RequiredArgsConstructor
public class {{.ControllerName}} {
    @Autowired
    private {{.ServiceName}} {{.ServiceVariableName}};
    {{- $svn := .ServiceVariableName}}

{{- range .HttpRuleMap}}

    {{if .Method.HasComment}}// {{.Method.Comment}}{{- end}}
    @{{.HttpMethod}}Mapping(path = "{{.HttpPath}}")
    public {{.ResponseBody.Type}} {{.Method.Name}}(
    {{- $len := (len .Params) -}}
    {{- if gt (len .Params) 1 }}
        {{- range $index, $param := .Params }}
        {{- if gt $index 0 }},{{end}}
        {{- "\n\t\t"}}{{.Annotation | safe}} {{.Type}} {{.Name}}
        {{- end }}
    ) {
    {{- else }}
        {{- range $index, $param := .Params }}
        {{- if gt $index 0}}, {{end}}
        {{- .Annotation | safe}} {{.Type}} {{ .Name -}}
        {{- end }}) {
    {{- end }}


    {{- if .HasRequestBody}}
        {{- if .PathParams | or .QueryParams }}
            {{- if not .IsWildcards }}
                {{ $rm := .RequestMessage }} {{ $rm.Type }} {{ $rm.Name }} = {{ $rm.Type }}.newBuilder()
                {{- range .PathParams}}
                    .set{{.Name | ucfirst}}({{.Name}})
                {{- end}}

                {{- range .QueryParams}}
                    .set{{.Name | ucfirst}}({{.Name}})
                {{- end}}
                .set{{.RequestBody.Name | ucfirst}}({{.RequestBody.Name}})
                .build();
            {{- end}}
        {{- end }}
    {{- else }}
        {{- if .PathParams | or .QueryParams }}
            {{ $rm := .RequestMessage }} {{ $rm.Type }} {{ $rm.Name }} = {{ $rm.Type }}.newBuilder()
            {{- range .PathParams}}
                .set{{.Name | ucfirst}}({{.Name}})
            {{- end}}

            {{- range .QueryParams}}
                .set{{.Name | ucfirst}}({{.Name}})
            {{- end}}
            .build();
        {{- else }}
            {{- $rm := .RequestMessage -}}
            {{ $rm.Type }} {{ $rm.Name }} = {{ $rm.Type }}.newBuilder().build();
        {{- end }}
    {{- end}}

        return {{$svn}}.{{.Method.Name}}({{.RequestMessage.Name}});
    }
{{- end}}
}
