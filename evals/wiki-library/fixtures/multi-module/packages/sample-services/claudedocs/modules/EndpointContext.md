---
doc_type: ai-module-spec
module_name: EndpointContext
owner: packages/sample-services
summary: 为请求提供与当前工作区绑定的服务端点上下文
feature_index:
  endpoint_context:
    entry: packages/sample-services/src/endpoint-context.ts#createEndpointContext
    body_section: 端点上下文
---

# EndpointContext

## 端点上下文

`EndpointContext` 将服务端点解析结果绑定到工作区标识。业务请求显式携带上下文，因此切换工作区不会改变已经创建的其他工作区请求客户端。

## 公开契约

- `createEndpointContext(workspaceId, endpoint)` 返回不可变的请求上下文。
- `resolveRequestTarget(context, path)` 只读取传入上下文，不读取全局当前工作区。
- 请求缓存键必须包含工作区标识和解析后的端点。

## 验证与风险

- 单元测试验证两个上下文对同一路径解析出不同目标。
- 若请求层读取全局端点，后台工作区的刷新会错误发送到前台工作区服务。
