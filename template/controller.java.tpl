package {{.PackageName}};

import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
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
        {{- "\n\t\t\t"}}{{.Annotation | safe}} {{.Type}} {{.Name}}
        {{- end }}
    ) {
    {{- else }}
        {{- range $index, $param := .Params }}
        {{- if gt $index 0}}, {{end}}
        {{- .Annotation | safe}} {{.Type}} {{ .Name -}}
        {{- end }}) { 
            
    {{- end }}
    {{- "\n\t\t\t"}}

    {{- if .HasRequestBody}}
        {{- if .PathParams | or .QueryParams }}
            {{- if not .IsWildcards }}
                {{- $rm := .RequestMessage -}} {{ $rm.Type }} {{ $rm.Name }} = {{ $rm.Type }}.newBuilder()
                {{- range .PathParams}}
                    {{- "\n\t\t\t  .set" }}{{.Name | ucfirst}}({{.Name}})
                {{- end}}

                {{- range .QueryParams}}
                    {{- "\n\t\t\t  .set" }}{{.Name | ucfirst}}({{.Name}})
                {{- end}}
                    {{- "\n\t\t\t  .set" }}{{.RequestBody.Name | ucfirst}}({{.RequestBody.Name}})
                {{- "\n\t\t\t  .build();" }}
            {{- end}}
        {{- end }}
    {{- else }}
        {{- if .PathParams | or .QueryParams }}
            {{- $rm := .RequestMessage -}} {{ $rm.Type }} {{ $rm.Name }} = {{ $rm.Type }}.newBuilder()
            {{- range .PathParams}}
                {{- "\n\t\t\t  .set" }}{{.Name | ucfirst}}({{.Name}})
            {{- end}}

            {{- range .QueryParams}}
                {{- "\n\t\t\t  .set" }}{{.Name | ucfirst}}({{.Name}})
            {{- end}}
            {{- "\n\t\t\t  .build();" }}
        {{- else }}
            {{- $rm := .RequestMessage -}} {{ $rm.Type }} {{ $rm.Name }} = {{ $rm.Type }}.newBuilder().build();
        {{- end }}
    {{- end}}
      return {{$svn}}.{{.Method.Name}}({{.RequestMessage.Name}});
    }
{{- end}}
}
