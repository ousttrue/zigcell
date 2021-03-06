const std = @import("std");
const types = @import("./types.zig");
const string = []const u8;

const Exists = struct {
    exists: bool,
};

fn Default(comptime T: type, comptime default_value: T) type {
    return struct {
        pub const value_type = T;
        pub const default = default_value;
        value: T,
    };
}

const MaybeStringArray = Default([]const []const u8, &.{});

pub const ClientCapabilities = struct {
    workspace: ?struct {
        workspaceFolders: Default(bool, false),
    },
    textDocument: ?struct {
        semanticTokens: Exists,
        hover: ?struct {
            contentFormat: MaybeStringArray,
        },
        completion: ?struct {
            completionItem: ?struct {
                snippetSupport: Default(bool, false),
                documentationFormat: MaybeStringArray,
            },
        },
    },
    offsetEncoding: MaybeStringArray,
};

pub const InitializeParams = struct {
    capabilities: ClientCapabilities,
    workspaceFolders: ?[]const types.WorkspaceFolder,
};

pub const ServerCapabilities = struct {
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
    offsetEncoding: string,
    serverInfo: struct {
        name: string,
        version: ?string = null,
    },
    capabilities: ServerCapabilities,
};
