import React, { useState, useRef, useCallback, useEffect } from 'react';
import ReactQuill, { Quill } from 'react-quill-new';
import 'react-quill-new/dist/quill.snow.css';
import { articleApi } from '../../../../services/articleApi';

// ---------- Custom Image Handler ----------
const ImageUploader = (quillRef: React.RefObject<ReactQuill | null>, onUploading: (v: boolean) => void) => {
    const input = document.createElement('input');
    input.setAttribute('type', 'file');
    input.setAttribute('accept', 'image/*');
    input.click();

    input.onchange = async () => {
        const file = input.files?.[0];
        if (!file) return;

        if (file.size > 5 * 1024 * 1024) {
            alert('Kích thước ảnh không được vượt quá 5MB');
            return;
        }

        try {
            onUploading(true);
            const { url } = await articleApi.uploadArticleContentImage(file);
            const quill = quillRef.current?.getEditor();
            if (quill) {
                const range = quill.getSelection(true);
                quill.insertEmbed(range.index, 'image', url, Quill.sources.USER);
                quill.setSelection(range.index + 1, 0);
            }
        } catch {
            alert('Tải ảnh lên thất bại. Vui lòng thử lại.');
        } finally {
            onUploading(false);
        }
    };
};

// ---------- Register custom style/class preserving blots (MUST be done before Quill renders) ----------
const Inline = Quill.import('blots/inline') as any;

// A generic inline blot that keeps style & class
class StyleInline extends Inline {
    static create(value: string) {
        const node = super.create() as HTMLElement;
        node.setAttribute('style', value);
        return node;
    }
    static formats(node: HTMLElement) {
        return node.getAttribute('style') || undefined;
    }
    format(name: string, value: string) {
        if (name === StyleInline.blotName && value) {
            (this.domNode as HTMLElement).setAttribute('style', value);
        } else {
            super.format(name, value);
        }
    }
}
StyleInline.blotName = 'inlineStyle';
StyleInline.tagName = 'span';

Quill.register({ 'formats/inlineStyle': StyleInline }, true);

// Clipboard matcher: preserve any inline style attribute on ANY element
const styleMatcherInline = (_node: HTMLElement, delta: any) => {
    const style = (_node as HTMLElement).getAttribute?.('style');
    if (style) {
        delta.ops = delta.ops.map((op: any) => {
            if (op.insert && typeof op.insert === 'string') {
                op.attributes = { ...(op.attributes || {}), inlineStyle: style };
            }
            return op;
        });
    }
    return delta;
};

// ---------- Toolbar Config ----------
const TOOLBAR_MODULES = (quillRef: React.RefObject<ReactQuill | null>, onUploading: (v: boolean) => void) => ({
    toolbar: {
        container: [
            [{ header: [1, 2, 3, 4, 5, 6, false] }],
            [{ font: [] }],
            [{ size: ['small', false, 'large', 'huge'] }],
            ['bold', 'italic', 'underline', 'strike'],
            [{ color: [] }, { background: [] }],
            [{ align: [] }],
            [{ list: 'ordered' }, { list: 'bullet' }],
            [{ indent: '-1' }, { indent: '+1' }],
            ['blockquote', 'code-block'],
            ['link', 'image', 'video'],
            ['clean'],
        ],
        handlers: {
            image: () => ImageUploader(quillRef, onUploading),
        },
    },
    clipboard: {
        matchVisual: false,
        matchers: [
            // Match any element and preserve its style attribute
            ['*', styleMatcherInline],
        ],
    },
});

const FORMATS = [
    'header', 'font', 'size',
    'bold', 'italic', 'underline', 'strike',
    'color', 'background',
    'align',
    'list', 'indent',
    'blockquote', 'code-block',
    'link', 'image', 'video',
    'inlineStyle',
];


// Strip Quill's always-present empty paragraph placeholder
// Quill adds <p><br></p> when the editor is empty or has trailing empty lines.
const cleanQuillHtml = (html: string): string => {
    // Remove trailing empty Quill paragraphs: <p><br></p> or <p class="..."><br></p>
    return html
        .replace(/<p(\s[^>]*)?><br\s*\/?><\/p>/gi, '')
        .trim();
};

// ---------- Component ----------
interface ArticleRichEditorProps {
    value: string;
    onChange: (html: string) => void;
}

const isComplexHtml = (html: string) => {
    if (!html) return false;
    // Check for common layout classes or elements that Quill doesn't support well natively
    return /class=".*(grid|flex|absolute|relative|w-full|h-auto|col-span|container).*"/.test(html) ||
           /<style|iframe/.test(html);
};

const ArticleRichEditor: React.FC<ArticleRichEditorProps> = ({ value, onChange }) => {
    // Determine initial mode based on content
    const [activeTab, setActiveTab] = useState<'visual' | 'html'>(isComplexHtml(value) ? 'html' : 'visual');
    const [currentValue, setCurrentValue] = useState(cleanQuillHtml(value));
    const [uploading, setUploading] = useState(false);
    const quillRef = useRef<ReactQuill | null>(null);

    // Keep state in sync when value changes externally (e.g., load article)
    const prevValueRef = useRef(value);
    useEffect(() => {
        if (value !== prevValueRef.current) {
            prevValueRef.current = value;
            setCurrentValue(cleanQuillHtml(value));
            if (isComplexHtml(value)) {
                setActiveTab('html');
            }
        }
    }, [value]);

    // Stable ref for onChange
    const onChangeRef = useRef(onChange);
    useEffect(() => { onChangeRef.current = onChange; }, [onChange]);

    // Intercept paste in Quill to preserve inline styles
    useEffect(() => {
        const timeout = setTimeout(() => {
            if (activeTab !== 'visual') return;
            const editor = quillRef.current?.getEditor();
            if (!editor) return;

            const editorDom = editor.root as HTMLElement;

            const handlePaste = (e: ClipboardEvent) => {
                const html = e.clipboardData?.getData('text/html');
                if (!html || html.trim() === '') return;

                e.preventDefault();
                e.stopPropagation();

                const selection = editor.getSelection(true);
                const index = selection ? selection.index : editor.getLength();
                (editor as any).clipboard.dangerouslyPasteHTML(index, html, 'user');

                setTimeout(() => {
                    const newHtml = cleanQuillHtml(editor.root.innerHTML);
                    setCurrentValue(newHtml);
                    onChangeRef.current(newHtml);
                    editor.setSelection(editor.getLength(), 0);
                }, 10);
            };

            editorDom.addEventListener('paste', handlePaste, true);
            (editorDom as any).__pasteHandler = handlePaste;
        }, 200);

        return () => {
            clearTimeout(timeout);
            const editor = quillRef.current?.getEditor();
            if (editor) {
                const dom = editor.root as any;
                if (dom.__pasteHandler) {
                    dom.removeEventListener('paste', dom.__pasteHandler, true);
                }
            }
        };
    // Re-bind when switching to visual tab
    // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [activeTab]);

    const modules = useCallback(
        () => TOOLBAR_MODULES(quillRef, setUploading),
        []
    );

    // Quill changed
    const handleVisualChange = (content: string) => {
        if (activeTab === 'visual') {
            const cleaned = cleanQuillHtml(content);
            setCurrentValue(cleaned);
            onChangeRef.current(cleaned);
        }
    };

    // Textarea changed
    const handleHtmlChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
        if (activeTab === 'html') {
            setCurrentValue(e.target.value);
            onChangeRef.current(e.target.value);
        }
    };

    // Visual → HTML: Snapshot Quill and switch
    const switchToHtml = () => {
        if (activeTab === 'html') return;
        const editor = quillRef.current?.getEditor();
        const currentHtml = editor ? cleanQuillHtml(editor.root.innerHTML) : currentValue;
        setCurrentValue(currentHtml);
        onChangeRef.current(currentHtml);
        setActiveTab('html');
    };

    // HTML → Visual: Warn user about data loss, then push into Quill
    const switchToVisual = () => {
        if (activeTab === 'visual') return;
        
        // Only warn if the HTML looks complex (has classes, divs, etc that Quill might strip)
        if (isComplexHtml(currentValue)) {
            const confirmSwitch = window.confirm(
                "CẢNH BÁO: Chuyển sang Trình soạn thảo (Visual) có thể làm mất các cấu trúc HTML phức tạp và class CSS tùy chỉnh (Tailwind) mà thẻ này không hỗ trợ. Bạn có chắc chắn muốn chuyển qua?"
            );
            if (!confirmSwitch) return;
        }

        setActiveTab('visual');
        // Let the unmount/remount happen naturally. Quill initializes with currentValue.
        // No need to copy dangerouslyPasteHTML here anymore because conditionally rendering 
        // `<ReactQuill value={currentValue} />` automatically seeds it properly.
    };



    return (
        <div className="rounded-xl border border-slate-200 dark:border-slate-700 overflow-hidden bg-white dark:bg-gray-900">
            {/* Tab Bar */}
            <div className="flex items-center border-b border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-gray-900/60 px-3 pt-2 gap-1">
                <button
                    type="button"
                    onClick={switchToVisual}
                    className={`px-4 py-1.5 text-sm font-medium rounded-t-lg transition-colors ${
                        activeTab === 'visual'
                            ? 'bg-white dark:bg-gray-800 text-dashboard-primary border border-b-white dark:border-slate-700 dark:border-b-gray-800 -mb-px'
                            : 'text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200'
                    }`}
                >
                    <span className="flex items-center gap-1.5">
                        <span className="material-symbols-outlined text-[16px]">edit</span>
                        Trình soạn thảo
                    </span>
                </button>
                <button
                    type="button"
                    onClick={switchToHtml}
                    className={`px-4 py-1.5 text-sm font-medium rounded-t-lg transition-colors ${
                        activeTab === 'html'
                            ? 'bg-white dark:bg-gray-800 text-dashboard-primary border border-b-white dark:border-slate-700 dark:border-b-gray-800 -mb-px'
                            : 'text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200'
                    }`}
                >
                    <span className="flex items-center gap-1.5">
                        <span className="material-symbols-outlined text-[16px]">html</span>
                        Mã HTML (Tùy chỉnh)
                    </span>
                </button>
                {uploading && (
                    <span className="ml-auto flex items-center gap-1.5 text-xs text-slate-500 dark:text-slate-400 pb-2">
                        <div className="w-3 h-3 border-2 border-dashboard-primary/40 border-t-dashboard-primary rounded-full animate-spin" />
                        Đang tải ảnh...
                    </span>
                )}
            </div>

            {/* Visual Editor */}
            {activeTab === 'visual' && (
                <div>
                    <style>{`
                        .article-quill .ql-toolbar {
                            border: none !important;
                            border-bottom: 1px solid #e2e8f0 !important;
                            padding: 8px 12px !important;
                            background: #f8fafc;
                        }
                        .dark .article-quill .ql-toolbar {
                            border-bottom-color: #374151 !important;
                            background: #111827;
                        }
                        .article-quill .ql-toolbar button,
                        .article-quill .ql-toolbar .ql-picker {
                            border-radius: 6px !important;
                        }
                        .article-quill .ql-toolbar button:hover,
                        .article-quill .ql-toolbar .ql-picker:hover {
                            background: #e2e8f0;
                        }
                        .dark .article-quill .ql-toolbar button:hover,
                        .dark .article-quill .ql-toolbar .ql-picker:hover {
                            background: #374151;
                        }
                        .article-quill .ql-container {
                            border: none !important;
                            font-size: 15px !important;
                            font-family: inherit !important;
                            background: inherit !important;
                            min-height: 480px;
                        }
                        .article-quill .ql-editor {
                            min-height: 480px;
                            padding: 20px !important;
                            color: #1e293b;
                        }
                        .dark .article-quill .ql-editor {
                            color: #f1f5f9;
                        }
                        .article-quill .ql-editor.ql-blank::before {
                            color: #94a3b8;
                            font-style: normal;
                        }
                        .dark .article-quill .ql-editor.ql-blank::before {
                            color: #64748b;
                        }
                        .article-quill .ql-editor img {
                            max-width: 100%;
                            border-radius: 8px;
                            cursor: pointer;
                        }
                        .article-quill .ql-editor h1 { font-size: 2em; font-weight: 700; margin: 16px 0 8px; }
                        .article-quill .ql-editor h2 { font-size: 1.5em; font-weight: 700; margin: 14px 0 7px; }
                        .article-quill .ql-editor h3 { font-size: 1.25em; font-weight: 600; margin: 12px 0 6px; }
                        .article-quill .ql-editor blockquote {
                            border-left: 4px solid #3b82f6;
                            padding-left: 16px;
                            color: #64748b;
                            margin: 12px 0;
                            font-style: italic;
                        }
                        .article-quill .ql-picker-options {
                            background: white !important;
                            border: 1px solid #e2e8f0 !important;
                            border-radius: 8px !important;
                            box-shadow: 0 8px 24px rgba(0,0,0,0.12) !important;
                        }
                        .dark .article-quill .ql-picker-options {
                            background: #1f2937 !important;
                            border-color: #374151 !important;
                        }
                        .dark .article-quill .ql-picker-item {
                            color: #e2e8f0 !important;
                        }
                    `}</style>
                    <div className="article-quill">
                        <ReactQuill
                            ref={quillRef}
                            theme="snow"
                            value={currentValue}
                            onChange={handleVisualChange}
                            modules={modules()}
                            formats={FORMATS}
                            placeholder="Nhập nội dung bài viết..."
                        />
                    </div>
                </div>
            )}

            {/* HTML Editor */}
            {activeTab === 'html' && (
                <div>
                    <textarea
                        value={currentValue}
                        onChange={handleHtmlChange}
                        className="w-full min-h-[480px] p-5 font-mono text-sm text-slate-800 dark:text-slate-200 bg-white dark:bg-gray-800 resize-y focus:outline-none leading-relaxed"
                        placeholder="<div class=&quot;grid grid-cols-2 gap-4&quot;>
  <p>Nhập mã HTML tùy chỉnh tại đây...</p>
</div>"
                        spellCheck={false}
                    />
                </div>
            )}
        </div>
    );
};

export default ArticleRichEditor;
