import { Outlet } from 'react-router-dom';
import logoImg from '../../assets/logo-rm-bg.png';

const AuthLayout = () => {
    return (
        <div className="flex min-h-screen w-full flex-col bg-background-light font-display text-[#1c1f22] dark:bg-background-dark dark:text-[#f9f7f6] lg:flex-row">
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
                        <img src={logoImg} alt="Logo" className="w-20 h-20 object-contain border-2 border-white shadow-sm bg-white" />
                        <span className="text-3xl font-bold tracking-tight">Nhinanchualanh.vn</span>
                    </div>
                    <p className="text-4xl font-bold leading-tight mb-6">Đánh thức bác sĩ tự thân trong cơ thể bạn.</p>
                    <p className="text-4xl font-bold leading-tight mb-6">Giải mã thông điệp cơ thể.</p>
                    <p className="text-4xl font-bold leading-tight mb-6">Lắng nghe để chữa lành.</p>
                    <div className="flex gap-2 mt-8">
                        <div className="h-1.5 w-8 bg-white rounded-full"></div>
                        <div className="h-1.5 w-2 bg-white/40 rounded-full"></div>
                        <div className="h-1.5 w-2 bg-white/40 rounded-full"></div>
                    </div>
                </div>
            </div>

            <div className="flex w-full flex-1 flex-col items-center justify-center overflow-y-auto px-4 py-8 sm:px-6 sm:py-10 lg:w-7/12 lg:px-10 xl:px-12">
                <div className="flex w-full max-w-md flex-col gap-6 sm:gap-8">
                    <div className="mb-2 flex justify-center sm:mb-4 lg:hidden">
                        <div className="flex items-center gap-2 text-primary dark:text-white">
                            <img src={logoImg} alt="Logo" className="h-12 w-12 border-2 border-primary object-contain shadow-sm sm:h-14 sm:w-14" />
                            <span className="max-w-[70vw] truncate text-2xl font-bold tracking-tight sm:text-3xl">NhinAnChuaLanh</span>
                        </div>
                    </div>

                    <Outlet />
                </div>
            </div>
        </div>
    );
};

export default AuthLayout;
