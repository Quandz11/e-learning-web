import React, { useState, useEffect, useRef } from 'react';
import { aiWidgetApi, type UserStudyPlan, type DailyStudyTask, type AiChatMessage } from '../../services/aiWidgetApi';
import { toast } from 'react-hot-toast';
import { useSelector } from 'react-redux';
import type { RootState } from '../../store/store';
import { format } from 'date-fns';

const AiChatWidget: React.FC = () => {
    const { isAuthenticated } = useSelector((state: RootState) => state.auth);
    const [isOpen, setIsOpen] = useState(false);
    const [isEnabled, setIsEnabled] = useState(false);
    
    // Core state
    const [plan, setPlan] = useState<UserStudyPlan | null>(null);
    const [tasks, setTasks] = useState<DailyStudyTask[]>([]);
    const [chatHistory, setChatHistory] = useState<AiChatMessage[]>([]);
    
    // UI state
    const [view, setView] = useState<'onboarding' | 'tasks' | 'chat'>('onboarding');
    const [loading, setLoading] = useState(false);
    const [chatInput, setChatInput] = useState('');
    
    // Onboarding form state
    const [goal, setGoal] = useState('');
    const [currentKnowledge, setCurrentKnowledge] = useState('');

    // Feedback state
    const [feedbackTaskId, setFeedbackTaskId] = useState<string | null>(null);
    const [feedbackText, setFeedbackText] = useState('');

    const chatEndRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        if (isAuthenticated) {
            checkStatusAndLoadData();
        }
    }, [isAuthenticated]);

    // Scroll chat to bottom
    useEffect(() => {
        if (view === 'chat' && chatEndRef.current) {
            chatEndRef.current.scrollIntoView({ behavior: 'smooth' });
        }
    }, [chatHistory, view]);

    const checkStatusAndLoadData = async () => {
        try {
            const status = await aiWidgetApi.getStatus();
            setIsEnabled(status.isEnabled);
            if (status.isEnabled) {
                await loadActivePlan();
            }
        } catch (error) {
            console.error('Failed to load AI widget status', error);
        }
    };

    const loadActivePlan = async () => {
        try {
            setLoading(true);
            const activePlan = await aiWidgetApi.getActivePlan();
            if (activePlan) {
                setPlan(activePlan);
                setView('tasks');
                await loadTasks(activePlan.id);
            } else {
                setView('onboarding');
            }
        } catch (error: any) {
            // Not found is expected if no plan exists - silently set to onboarding
            if (error?.statusCode !== 404) {
                console.error('Error loading plan', error);
            }
            setView('onboarding');
        } finally {
            setLoading(false);
        }
    };

    const loadTasks = async (planId: string) => {
        try {
            const todayTasks = await aiWidgetApi.getTodayTasks(planId);
            setTasks(todayTasks);
        } catch (error) {
            console.error('Error loading tasks', error);
        }
    };

    const loadChatHistory = async () => {
        try {
            const history = await aiWidgetApi.getChatHistory();
            setChatHistory(history);
        } catch (error) {
            console.error('Error loading chat history', error);
        }
    };

    const handleInitPlan = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            setLoading(true);
            const newPlan = await aiWidgetApi.initPlan(goal, currentKnowledge);
            setPlan(newPlan);
            toast.success("Đã tạo lộ trình thành công!");
            setView('tasks');
            await loadTasks(newPlan.id);
        } catch (error: any) {
            const msg = error?.message || "Lỗi khi tạo lộ trình";
            if (msg.includes('not configured') || msg.includes('disabled')) {
                toast.error("AI chưa được cấu hình. Admin cần thiết lập API Key Gemini trước.");
            } else {
                toast.error(msg);
            }
        } finally {
            setLoading(false);
        }
    };

    const handleSubmitTask = async (taskId: string) => {
        if (!feedbackText.trim()) {
            toast.error("Vui lòng nhập chút phản hồi về task này nhé!");
            return;
        }

        try {
            setLoading(true);
            const updatedTask = await aiWidgetApi.submitTask(taskId, feedbackText);
            
            // Reload tasks manually or remove this task from state
            setTasks(prev => prev.filter(t => t.id !== taskId));
            
            // Show AI advice via Toast for now, or display in UI
            toast.success("Hay quá! Phản hồi từ gia sư: " + updatedTask.aiAdvice, {
                duration: 6000,
                icon: '🎉'
            });

            setFeedbackTaskId(null);
            setFeedbackText('');
        } catch (error: any) {
            toast.error(error.message || "Lỗi khi cập nhật task");
        } finally {
            setLoading(false);
        }
    };

    const handleSendChat = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!chatInput.trim()) return;

        const userMsg = chatInput;
        setChatInput('');
        
        // Optimistic UI update
        const tempId = Date.now().toString();
        setChatHistory(prev => [...prev, { id: tempId, role: 'user', content: userMsg, createdAt: new Date().toISOString() }]);

        try {
            setLoading(true);
            const { response } = await aiWidgetApi.chat(userMsg);
            setChatHistory(prev => [...prev, { id: tempId + 'ai', role: 'model', content: response, createdAt: new Date().toISOString() }]);
        } catch (error: any) {
            toast.error("Lỗi gửi tin nhắn");
            setChatHistory(prev => prev.filter(m => m.id !== tempId));
        } finally {
            setLoading(false);
        }
    };

    if (!isAuthenticated || !isEnabled) return null;

    return (
        <div className="fixed bottom-40 right-6 z-50 flex flex-col items-end">
            {/* Chat Box */}
            {isOpen && (
                <div className="mb-4 w-[350px] sm:w-[400px] h-[500px] bg-white dark:bg-gray-900 rounded-2xl shadow-2xl border border-gray-100 dark:border-gray-800 flex flex-col overflow-hidden animate-slideUp">
                    {/* Header */}
                    <div className="bg-gradient-to-r from-primary to-primary-light text-white p-4 flex justify-between items-center shrink-0">
                        <div className="flex items-center gap-2">
                            <span className="material-symbols-outlined text-[24px]">smart_toy</span>
                            <span className="font-semibold text-lg drop-shadow-sm">Gia sư AI</span>
                        </div>
                        <button onClick={() => setIsOpen(false)} className="hover:bg-white/20 p-1 rounded-full transition-colors leading-none">
                            <span className="material-symbols-outlined text-[20px]">close</span>
                        </button>
                    </div>

                    {/* Navigation Tabs (Only if Plan exists) */}
                    {plan && (
                        <div className="flex border-b border-gray-100 dark:border-gray-800 shrink-0 bg-gray-50 dark:bg-gray-900/50">
                            <button 
                                onClick={() => setView('tasks')}
                                className={`flex-1 py-3 text-sm font-medium transition-colors ${view === 'tasks' ? 'text-primary border-b-2 border-primary' : 'text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800'}`}
                            >
                                Nhiệm vụ hôm nay
                            </button>
                            <button 
                                onClick={() => {
                                    setView('chat');
                                    loadChatHistory();
                                }}
                                className={`flex-1 py-3 text-sm font-medium transition-colors ${view === 'chat' ? 'text-primary border-b-2 border-primary' : 'text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800'}`}
                            >
                                Trò chuyện
                            </button>
                        </div>
                    )}

                    {/* Content Area */}
                    <div className="flex-1 overflow-y-auto bg-gray-50 dark:bg-gray-900/50 p-4 relative">
                        {loading && view !== 'chat' && (
                            <div className="absolute inset-0 bg-white/50 dark:bg-gray-900/50 flex items-center justify-center z-10 backdrop-blur-sm">
                                <span className="material-symbols-outlined animate-spin text-primary text-[32px]">progress_activity</span>
                            </div>
                        )}

                        {/* VIEW: ONBOARDING */}
                        {view === 'onboarding' && (
                            <div className="h-full flex flex-col justify-center animate-fadeIn">
                                <div className="text-center mb-6">
                                    <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-3">
                                        <span className="material-symbols-outlined text-[32px] text-primary">school</span>
                                    </div>
                                    <h3 className="text-xl font-bold text-gray-900 dark:text-white">Chào bạn!</h3>
                                    <p className="text-gray-500 text-sm mt-1 px-4">Mình là gia sư AI. Hãy nói cho mình biết mục tiêu học tập của bạn để mình lên lịch phù hợp nhé.</p>
                                </div>
                                
                                <form onSubmit={handleInitPlan} className="space-y-4">
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Mục tiêu bạn muốn đạt được?</label>
                                        <input 
                                            type="text" 
                                            required
                                            value={goal}
                                            onChange={e => setGoal(e.target.value)}
                                            placeholder="Vd: Pass môn Lập trình Web"
                                            className="w-full px-4 py-2 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl focus:ring-2 focus:ring-primary focus:border-transparent outline-none text-gray-900 dark:text-white transition-shadow"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Kiến thức của bạn hiện tại?</label>
                                        <input 
                                            type="text" 
                                            required
                                            value={currentKnowledge}
                                            onChange={e => setCurrentKnowledge(e.target.value)}
                                            placeholder="Vd: Đã biết cơ bản về HTML CSS"
                                            className="w-full px-4 py-2 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl focus:ring-2 focus:ring-primary focus:border-transparent outline-none text-gray-900 dark:text-white transition-shadow"
                                        />
                                    </div>
                                    <button 
                                        type="submit" 
                                        disabled={loading}
                                        className="w-full py-2.5 bg-primary text-white rounded-xl font-medium hover:bg-primary-dark transition-colors mt-2"
                                    >
                                        Tạo lộ trình cá nhân
                                    </button>
                                </form>
                            </div>
                        )}

                        {/* VIEW: TASKS */}
                        {view === 'tasks' && (
                            <div className="animate-fadeIn space-y-4">
                                {tasks.length === 0 ? (
                                    <div className="text-center py-10">
                                        <span className="material-symbols-outlined text-[48px] text-green-500 mb-2">task_alt</span>
                                        <h4 className="font-semibold text-gray-900 dark:text-white">Tuyệt vời!</h4>
                                        <p className="text-sm text-gray-500">Bạn đã hoàn thành mọi nhiệm vụ xuất sắc ngày hôm nay.</p>
                                    </div>
                                ) : (
                                    tasks.map(task => (
                                        <div key={task.id} className="bg-white dark:bg-gray-800 p-4 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700">
                                            <div className="flex gap-3 items-start">
                                                <div 
                                                    className="shrink-0 w-6 h-6 mt-0.5 rounded-full border-2 border-gray-300 dark:border-gray-600 flex items-center justify-center cursor-pointer hover:border-primary transition-colors"
                                                    onClick={() => setFeedbackTaskId(feedbackTaskId === task.id ? null : task.id)}
                                                >
                                                    {feedbackTaskId === task.id && <div className="w-3 h-3 bg-primary rounded-full"></div>}
                                                </div>
                                                <div>
                                                    <p className="text-gray-900 dark:text-white text-sm font-medium leading-relaxed">{task.content}</p>
                                                    <p className="text-xs text-gray-500 mt-1 flex items-center gap-1">
                                                        <span className="material-symbols-outlined text-[14px]">calendar_today</span>
                                                        {format(new Date(task.taskDate), 'dd/MM/yyyy')}
                                                    </p>
                                                </div>
                                            </div>

                                            {/* Feedback Form Slide Down */}
                                            {feedbackTaskId === task.id && (
                                                <div className="mt-4 pt-4 border-t border-gray-100 dark:border-gray-700 animate-fadeIn">
                                                    <p className="text-xs text-gray-600 dark:text-gray-400 mb-2 font-medium">Bạn cảm thấy task này thế nào?</p>
                                                    <textarea
                                                        value={feedbackText}
                                                        onChange={(e) => setFeedbackText(e.target.value)}
                                                        placeholder="Vd: Mình làm hơi vấp phần X, Y cần cải thiện thêm"
                                                        rows={2}
                                                        className="w-full px-3 py-2 bg-gray-50 dark:bg-gray-900 text-sm border border-gray-200 dark:border-gray-600 rounded-lg focus:ring-1 focus:ring-primary outline-none transition-shadow text-gray-800 dark:text-gray-200 resize-none"
                                                    />
                                                    <div className="mt-2 flex justify-end gap-2">
                                                        <button 
                                                            onClick={() => setFeedbackTaskId(null)}
                                                            className="px-3 py-1.5 text-xs font-medium text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-800 rounded-lg transition-colors"
                                                        >
                                                            Hủy
                                                        </button>
                                                        <button 
                                                            onClick={() => handleSubmitTask(task.id)}
                                                            className="px-3 py-1.5 text-xs font-medium bg-primary text-white rounded-lg hover:bg-primary-dark transition-colors flex items-center gap-1"
                                                        >
                                                            Hoàn thành
                                                        </button>
                                                    </div>
                                                </div>
                                            )}
                                        </div>
                                    ))
                                )}
                            </div>
                        )}

                        {/* VIEW: CHAT */}
                        {view === 'chat' && (
                            <div className="h-full flex flex-col">
                                <div className="flex-1 overflow-y-auto space-y-4 pb-2 pr-2">
                                    {chatHistory.length === 0 && (
                                        <div className="text-center text-gray-400 text-sm mt-10">
                                            Bắt đầu trò chuyện với Gia sư AI.
                                        </div>
                                    )}
                                    {chatHistory.map(msg => (
                                        <div key={msg.id} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                                            <div className={`max-w-[85%] rounded-2xl px-4 py-2.5 text-sm shadow-sm ${
                                                msg.role === 'user' 
                                                    ? 'bg-primary text-white rounded-br-none' 
                                                    : 'bg-white dark:bg-gray-800 text-gray-800 dark:text-gray-200 border border-gray-100 dark:border-gray-700 rounded-bl-none'
                                            }`}>
                                                {msg.content}
                                            </div>
                                        </div>
                                    ))}
                                    {loading && view === 'chat' && (
                                        <div className="flex justify-start">
                                            <div className="bg-white dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-2xl rounded-bl-none px-4 py-2.5 flex items-center gap-1">
                                                <div className="w-1.5 h-1.5 bg-gray-400 rounded-full animate-bounce"></div>
                                                <div className="w-1.5 h-1.5 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.2s'}}></div>
                                                <div className="w-1.5 h-1.5 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.4s'}}></div>
                                            </div>
                                        </div>
                                    )}
                                    <div ref={chatEndRef} />
                                </div>
                                <form onSubmit={handleSendChat} className="mt-auto bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl p-1 shadow-sm flex items-center overflow-hidden shrink-0">
                                    <input 
                                        type="text" 
                                        value={chatInput}
                                        onChange={e => setChatInput(e.target.value)}
                                        placeholder="Hỏi gia sư AI..."
                                        disabled={loading}
                                        className="flex-1 px-3 py-2 bg-transparent outline-none text-sm text-gray-900 dark:text-white"
                                    />
                                    <button 
                                        type="submit" 
                                        disabled={!chatInput.trim() || loading}
                                        className="w-8 h-8 rounded-lg bg-primary text-white flex items-center justify-center disabled:opacity-50 hover:bg-primary-dark transition-colors mr-1"
                                    >
                                        <span className="material-symbols-outlined text-[16px]">send</span>
                                    </button>
                                </form>
                            </div>
                        )}
                    </div>
                </div>
            )}

            {/* Floating Toggle Button */}
            <button
                onClick={() => setIsOpen(!isOpen)}
                className={`flex items-center justify-center w-14 h-14 rounded-full shadow-2xl transition-all duration-300 hover:scale-105 active:scale-95 z-50 overflow-hidden relative group cursor-pointer border-none bg-gradient-to-tr from-primary to-primary-light`}
            >
                {/* Glow effect behind */}
                <div className="absolute inset-0 bg-primary/30 blur-xl rounded-full scale-150 group-hover:bg-primary/50 transition-colors"></div>
                
                {isOpen ? (
                    <span className="material-symbols-outlined text-white text-[28px] relative z-10 animate-scaleIn">close</span>
                ) : (
                    <span className="material-symbols-outlined text-white text-[28px] relative z-10 animate-scaleIn">smart_toy</span>
                )}
            </button>
        </div>
    );
};

export default AiChatWidget;
