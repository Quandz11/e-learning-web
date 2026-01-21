
import { Outlet } from 'react-router-dom';

const AuthLayout = () => {
    return (
        <div className="flex flex-1 w-full min-h-screen bg-background-light dark:bg-background-dark font-display text-[#1c1f22] dark:text-[#f9f7f6]">
            {/* Visual Panel (Left side) */}
            <div className="hidden lg:flex w-5/12 relative flex-col justify-end p-12 bg-primary overflow-hidden">
                <div className="absolute inset-0 z-0">
                    <img
                        alt="Students collaborating around a table in a modern library"
                        className="w-full h-full object-cover mix-blend-overlay opacity-40"
                        src="https://lh3.googleusercontent.com/aida-public/AB6AXuA6wWB5sVNe05UpvyfkVbAub7bSwSCj4lk7kisNOgyEd90Zgf6GiWaMxRpY-H8q9r7B2lBz_ooHFL1NUVxrChSKkolYcT6uzLlUKihDd5SyPZ3owo02-naivIzcwnU8_PMIMbjZZyuV8Tx72L8w_ytUFmNi_8ZqFsFt2q_XW3E-jbLPfmRBkAnj6wUI_JiqXCZebIsg3sX3jtF-RjgXt2stvdV2A6eIyFRC81ahblDaHzruNaXPI-KJR7n4gDi6fL2Dgx7iGJA9LQ"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-primary/90 to-primary/40 mix-blend-multiply"></div>
                </div>
                <div className="relative z-10 text-white max-w-md">
                    <div className="flex items-center gap-2 mb-8">
                        <span className="material-symbols-outlined text-4xl">school</span>
                        <span className="text-2xl font-bold tracking-tight">SKVI-Learning</span>
                    </div>
                    <h1 className="text-5xl font-bold leading-tight mb-6">Khai phá tiềm năng của bạn qua mỗi bài học.</h1>
                    <p className="text-lg opacity-90 leading-relaxed">Tham gia cộng đồng những người học tập suốt đời và làm chủ các kỹ năng mới theo tốc độ của riêng bạn.</p>
                    <div className="flex gap-2 mt-8">
                        <div className="h-1.5 w-8 bg-white rounded-full"></div>
                        <div className="h-1.5 w-2 bg-white/40 rounded-full"></div>
                        <div className="h-1.5 w-2 bg-white/40 rounded-full"></div>
                    </div>
                </div>
            </div>

            {/* Form Panel (Right side) */}
            <div className="w-full lg:w-7/12 flex flex-col items-center justify-center p-6 sm:p-12 overflow-y-auto">
                <div className="w-full max-w-md flex flex-col gap-8">
                    {/* Mobile Branding */}
                    <div className="lg:hidden flex justify-center mb-4">
                        <div className="flex items-center gap-2 text-primary dark:text-white">
                            <span className="material-symbols-outlined text-4xl">school</span>
                            <span className="text-2xl font-bold tracking-tight">SKVI-learning</span>
                        </div>
                    </div>

                    <Outlet />
                </div>
            </div>
        </div>
    );
};

export default AuthLayout;
