const std = @import("std");
const string = []const u8;

pub const ServerCapabilities = struct {
    offsetEncoding: string,
    signatureHelpProvider: struct {
        triggerCharacters: []const string,
        retriggerCharacters: []const string,
    },
    textDocumentSync: enum(u32) {
        None = 0,
        Full = 1,
        Incremental = 2,

        pub fn jsonStringify(value: @This(), options: std.json.StringifyOptions, out_stream: anytype) !void {
            try std.json.stringify(@enumToInt(value), options, out_stream);
        }
    },
    renameProvider: bool,
    completionProvider: struct {
        resolveProvider: bool,
        triggerCharacters: []const string,
    },
    documentHighlightProvider: bool,
    hoverProvider: bool,
    codeActionProvider: bool,
    declarationProvider: bool,
    definitionProvider: bool,
    typeDefinitionProvider: bool,
    implementationProvider: bool,
    referencesProvider: bool,
    documentSymbolProvider: bool,
    colorProvider: bool,
    documentFormattingProvider: bool,
    documentRangeFormattingProvider: bool,
    foldingRangeProvider: bool,
    selectionRangeProvider: bool,
    workspaceSymbolProvider: bool,
    rangeProvider: bool,
    documentProvider: bool,
    workspace: ?struct {
        workspaceFolders: ?struct {
            supported: bool,
            changeNotifications: bool,
        },
    },
    semanticTokensProvider: struct {
        full: bool,
        range: bool,
        legend: struct {
            tokenTypes: []const string,
            tokenModifiers: []const string,
        },
    },
};

pub const InitializeResult = struct {
    serverInfo: struct {
        name: string,
        version: ?string = null,
    },
    capabilities: ServerCapabilities,
};
