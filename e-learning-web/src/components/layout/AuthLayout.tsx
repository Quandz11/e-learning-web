
import { Outlet } from 'react-router-dom';
import logoImg from '../../assets/logo.jpg';

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
                        <img src={logoImg} alt="Logo" className="w-20 h-20 object-cover rounded-full border-2 border-white bg-white shadow-sm" />
                        <span className="text-3xl font-bold tracking-tight">Nhinanchualanh.vn</span>
                    </div>
                    <h1 className="text-4xl font-bold leading-tight mb-6">Đánh thức bác sĩ tự thân trong cơ thể bạn.</h1>
                               <h1 className="text-4xl font-bold leading-tight mb-6">Giải mã thông điệp cơ thể.</h1>
                    <p className="text-4xl font-bold leading-tight mb-6">Lắng nghe để chữa lành.</p>
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
                            <img src={logoImg} alt="Logo" className="w-16 h-16 object-cover rounded-full border-2 border-primary bg-white shadow-sm" />
                            <span className="text-3xl font-bold tracking-tight">NhinAnChuaLanh</span>
                        </div>
                    </div>

                    <Outlet />
                </div>
            </div>
        </div>
    );
};

export default AuthLayout;
