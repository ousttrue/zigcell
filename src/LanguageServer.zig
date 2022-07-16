const std = @import("std");
const lsp = @import("lsp");
const Self = @This();

dummy: i32 = undefined,

pub fn initialize(self: *Self, params: ?std.json.Value) !lsp.response.ResponseResult {
    _ = self;
    _ = params;
    // for (req.params.capabilities.offsetEncoding.value) |encoding| {
    //     if (std.mem.eql(u8, encoding, "utf-8")) {
    //         offsets.offset_encoding = .utf8;
    //     }
    // }

    // if (req.params.capabilities.textDocument) |textDocument| {
    //     client_capabilities.supports_semantic_tokens = textDocument.semanticTokens.exists;
    //     if (textDocument.hover) |hover| {
    //         for (hover.contentFormat.value) |format| {
    //             if (std.mem.eql(u8, "markdown", format)) {
    //                 client_capabilities.hover_supports_md = true;
    //             }
    //         }
    //     }
    //     if (textDocument.completion) |completion| {
    //         if (completion.completionItem) |completionItem| {
    //             client_capabilities.supports_snippets = completionItem.snippetSupport.value;
    //             for (completionItem.documentationFormat.value) |documentationFormat| {
    //                 if (std.mem.eql(u8, "markdown", documentationFormat)) {
    //                     client_capabilities.completion_doc_supports_md = true;
    //                 }
    //             }
    //         }
    //     }
    // }

    // logger.info("zls initialized", .{});
    // logger.info("{}", .{client_capabilities});
    // logger.info("Using offset encoding: {s}", .{@tagName(offsets.offset_encoding)});

    return lsp.response.ResponseResult{
        .initialize = .{
            .offsetEncoding = "utf-16",
            .serverInfo = .{
                .name = "zigcell",
                .version = "0.1.0",
            },
            .capabilities = .{
                .signatureHelpProvider = .{
                    .triggerCharacters = &.{"("},
                    .retriggerCharacters = &.{","},
                },
                .textDocumentSync = .Full,
                .renameProvider = true,
                .completionProvider = .{
                    .resolveProvider = false,
                    .triggerCharacters = &[_][]const u8{ ".", ":", "@" },
                },
                .documentHighlightProvider = false,
                .hoverProvider = true,
                .codeActionProvider = false,
                .declarationProvider = true,
                .definitionProvider = true,
                .typeDefinitionProvider = true,
                .implementationProvider = false,
                .referencesProvider = true,
                .documentSymbolProvider = true,
                .colorProvider = false,
                .documentFormattingProvider = true,
                .documentRangeFormattingProvider = false,
                .foldingRangeProvider = false,
                .selectionRangeProvider = false,
                .workspaceSymbolProvider = false,
                .rangeProvider = false,
                .documentProvider = true,
                .workspace = .{
                    .workspaceFolders = .{
                        .supported = false,
                        .changeNotifications = false,
                    },
                },
                .semanticTokensProvider = .{
                    .full = true,
                    .range = false,
                    .legend = .{
                        .tokenTypes = comptime block: {
                            const tokTypeFields = std.meta.fields(lsp.semantic_token.SemanticTokenType);
                            var names: [tokTypeFields.len][]const u8 = undefined;
                            for (tokTypeFields) |field, i| {
                                names[i] = field.name;
                            }
                            break :block &names;
                        },
                        .tokenModifiers = comptime block: {
                            const tokModFields = std.meta.fields(lsp.semantic_token.SemanticTokenModifiers);
                            var names: [tokModFields.len][]const u8 = undefined;
                            for (tokModFields) |field, i| {
                                names[i] = field.name;
                            }
                            break :block &names;
                        },
                    },
                },
            },
        },
    };
}
