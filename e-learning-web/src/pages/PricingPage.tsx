import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

type CtaVariant = 'primary' | 'outline' | 'accent';

interface PricingFeature {
  text: string;
  highlight?: boolean;
}

interface PricingPackage {
  id: string;
  name: string;
  price: string;
  desc: string;
  features: PricingFeature[];
  cta: string;
  ctaTo: string;
  ctaVariant: CtaVariant;
  featured?: boolean;
  badge?: string;
}

const PricingPage: React.FC = () => {
  const { t } = useTranslation();
  const [openFaqIndex, setOpenFaqIndex] = useState<number | null>(0);

  const packages: PricingPackage[] = [
    {
      id: 'course99k',
      name: t('pricingPage.packages.course99k.name'),
      price: t('pricingPage.packages.course99k.price'),
      desc: t('pricingPage.packages.course99k.desc'),
      features: [
        { text: t('pricingPage.packages.course99k.features.0') },
        { text: t('pricingPage.packages.course99k.features.1'), highlight: true },
      ],
      cta: t('pricingPage.packages.course99k.cta'),
      ctaTo: '/courses',
      ctaVariant: 'outline',
    },
    {
      id: 'challenge',
      name: t('pricingPage.packages.challenge.name'),
      price: t('pricingPage.packages.challenge.price'),
      desc: t('pricingPage.packages.challenge.desc'),
      features: [
        { text: t('pricingPage.packages.challenge.features.0') },
        { text: t('pricingPage.packages.challenge.features.1') },
        { text: t('pricingPage.packages.challenge.features.2') },
      ],
      cta: t('pricingPage.packages.challenge.cta'),
      ctaTo: '/courses',
      ctaVariant: 'primary',
    },
    {
      id: 'trainingMeditation',
      name: t('pricingPage.packages.trainingMeditation.name'),
      price: t('pricingPage.packages.trainingMeditation.price'),
      desc: t('pricingPage.packages.trainingMeditation.desc'),
      features: [
        { text: t('pricingPage.packages.trainingMeditation.features.0') },
        { text: t('pricingPage.packages.trainingMeditation.features.1') },
        { text: t('pricingPage.packages.trainingMeditation.features.2'), highlight: true },
      ],
      cta: t('pricingPage.packages.trainingMeditation.cta'),
      ctaTo: '/courses',
      ctaVariant: 'outline',
    },
    {
      id: 'basicFull',
      name: t('pricingPage.packages.basicFull.name'),
      price: t('pricingPage.packages.basicFull.price'),
      desc: t('pricingPage.packages.basicFull.desc'),
      features: [
        { text: t('pricingPage.packages.basicFull.features.0') },
        { text: t('pricingPage.packages.basicFull.features.1'), highlight: true },
        { text: t('pricingPage.packages.basicFull.features.2'), highlight: true },
        { text: t('pricingPage.packages.basicFull.features.3') },
      ],
      cta: t('pricingPage.packages.basicFull.cta'),
      ctaTo: '/courses',
      ctaVariant: 'primary',
      featured: true,
      badge: t('pricingPage.packages.basicFull.badge'),
    },
    {
      id: 'obesityReset',
      name: t('pricingPage.packages.obesityReset.name'),
      price: t('pricingPage.packages.obesityReset.price'),
      desc: t('pricingPage.packages.obesityReset.desc'),
      features: [
        { text: t('pricingPage.packages.obesityReset.features.0') },
        { text: t('pricingPage.packages.obesityReset.features.1'), highlight: true },
        { text: t('pricingPage.packages.obesityReset.features.2'), highlight: true },
        { text: t('pricingPage.packages.obesityReset.features.3') },
      ],
      cta: t('pricingPage.packages.obesityReset.cta'),
      ctaTo: '/courses',
      ctaVariant: 'primary',
    },
    {
      id: 'fullTransformation',
      name: t('pricingPage.packages.fullTransformation.name'),
      price: t('pricingPage.packages.fullTransformation.price'),
      desc: t('pricingPage.packages.fullTransformation.desc'),
      features: [
        { text: t('pricingPage.packages.fullTransformation.features.0') },
        { text: t('pricingPage.packages.fullTransformation.features.1') },
        { text: t('pricingPage.packages.fullTransformation.features.2'), highlight: true },
        { text: t('pricingPage.packages.fullTransformation.features.3') },
      ],
      cta: t('pricingPage.packages.fullTransformation.cta'),
      ctaTo: '/ambassador#register',
      ctaVariant: 'accent',
    },
  ];

  const policyItems = [
    t('pricingPage.policies.items.0'),
    t('pricingPage.policies.items.1'),
    t('pricingPage.policies.items.2'),
  ];

  const faqItems = [
    {
      q: t('pricingPage.faq.items.0.q'),
      a: t('pricingPage.faq.items.0.a'),
    },
    {
      q: t('pricingPage.faq.items.1.q'),
      a: t('pricingPage.faq.items.1.a'),
    },
    {
      q: t('pricingPage.faq.items.2.q'),
      a: t('pricingPage.faq.items.2.a'),
    },
  ];

  const getCtaClass = (variant: CtaVariant): string => {
    if (variant === 'outline') {
      return 'border-2 border-primary bg-transparent text-primary hover:bg-primary/10';
    }

    if (variant === 'accent') {
      return 'bg-[#ffb703] text-black hover:bg-[#f4ae19]';
    }

    return 'bg-primary text-white hover:bg-primary/90';
  };

  return (
    <div className="bg-[#f8f9fa] py-12 sm:py-14">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <section className="mb-10 text-center sm:mb-12">
          <h1 className="text-3xl font-extrabold text-[#1b4332] sm:text-4xl lg:text-5xl">{t('pricingPage.hero.title')}</h1>
          <p className="mx-auto mt-3 max-w-3xl text-sm text-[#2d6a4f]/85 sm:text-base">{t('pricingPage.hero.subtitle')}</p>
        </section>

        <section className="grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-3">
          {packages.map((pkg) => (
            <article
              key={pkg.id}
              className={`relative flex h-full flex-col rounded-2xl border bg-white p-6 text-center transition-all duration-300 hover:-translate-y-1 hover:shadow-xl ${
                pkg.featured
                  ? 'scale-[1.01] border-[2.5px] border-[#40916c] shadow-[0_12px_30px_rgba(27,67,50,0.12)]'
                  : 'border-gray-100 shadow-[0_10px_24px_rgba(0,0,0,0.06)]'
              }`}
            >
              {pkg.badge && (
                <span className="absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-[#ffb703] px-3 py-1 text-xs font-extrabold text-black">
                  {pkg.badge}
                </span>
              )}

              <h2 className="min-h-[3.2rem] text-lg font-bold text-[#2d6a4f]">{pkg.name}</h2>
              <p className="mt-2 text-3xl font-extrabold text-[#1f2937]">{pkg.price}</p>
              <p className="mt-2 min-h-[3.2rem] text-sm text-gray-600">{pkg.desc}</p>

              <ul className="mt-5 flex-1 space-y-2 text-left text-sm text-gray-700">
                {pkg.features.map((feature) => (
                  <li key={feature.text} className="relative pl-6">
                    <span className="absolute left-0 top-0 font-bold text-[#40916c]">✓</span>
                    <span className={feature.highlight ? 'font-semibold text-[#d90429]' : ''}>{feature.text}</span>
                  </li>
                ))}
              </ul>

              <Link
                to={pkg.ctaTo}
                className={`mt-6 block rounded-lg px-4 py-3 text-sm font-bold transition-colors ${getCtaClass(pkg.ctaVariant)}`}
              >
                {pkg.cta}
              </Link>
            </article>
          ))}
        </section>

        <section className="mt-10 rounded-2xl bg-gradient-to-r from-[#2d6a4f] to-[#40916c] px-6 py-7 text-center text-white sm:mt-12 sm:px-8 sm:py-9">
          <h2 className="text-xl font-extrabold sm:text-2xl">{t('pricingPage.ambassador.title')}</h2>
          <p className="mx-auto mt-2 max-w-2xl text-sm text-white/90 sm:text-base">{t('pricingPage.ambassador.subtitle')}</p>
          <Link to="/ambassador" className="mt-4 inline-flex items-center justify-center text-sm font-bold text-[#ffb703] underline underline-offset-4">
            {t('pricingPage.ambassador.cta')}
          </Link>
        </section>

        <section id="pricing-policies" className="mt-10 sm:mt-12">
          <h2 className="inline-block border-b-[3px] border-[#ffb703] pb-1 text-2xl font-bold text-[#2d6a4f]">{t('pricingPage.policies.title')}</h2>
          <div className="mt-4 rounded-2xl bg-white p-6 shadow-[0_8px_20px_rgba(0,0,0,0.06)]">
            <ul className="space-y-3 text-sm text-gray-700 sm:text-base">
              {policyItems.map((item) => (
                <li key={item} className="leading-relaxed">
                  {item}
                </li>
              ))}
            </ul>
          </div>
        </section>

        <section className="mt-10 sm:mt-12">
          <h2 className="inline-block border-b-[3px] border-[#ffb703] pb-1 text-2xl font-bold text-[#2d6a4f]">{t('pricingPage.faq.title')}</h2>
          <div className="mt-4 max-w-4xl space-y-3">
            {faqItems.map((faq, index) => {
              const isOpen = openFaqIndex === index;

              return (
                <article
                  key={faq.q}
                  className={`overflow-hidden rounded-xl border bg-white transition-all ${isOpen ? 'border-[#40916c]' : 'border-gray-100'}`}
                >
                  <button
                    type="button"
                    onClick={() => setOpenFaqIndex((prev) => (prev === index ? null : index))}
                    className="flex w-full items-center justify-between px-5 py-4 text-left"
                  >
                    <span className="pr-3 text-sm font-bold text-[#1b4332] sm:text-base">{faq.q}</span>
                    <span className="text-lg font-bold text-[#2d6a4f]">{isOpen ? '−' : '+'}</span>
                  </button>
                  {isOpen && <div className="border-t border-gray-100 px-5 pb-4 pt-3 text-sm leading-relaxed text-gray-700">{faq.a}</div>}
                </article>
              );
            })}
          </div>
        </section>
      </div>
    </div>
  );
};

export default PricingPage;
